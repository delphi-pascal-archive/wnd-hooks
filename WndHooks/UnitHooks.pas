{*******************************************************************************
*     UnitHooks позволит Вам перекрывать оконные процедуры WndProc контролов
*     Есть возможность перекрыть несколько WndProc создавая при этом только
*        один обработчик.
*     Количество обработчиков для одного контрола не ограничено
*
*     Разработчик: Шастун Валерий swalery@yandex.ru
*     2009 Москва
*******************************************************************************}
unit UnitHooks;

interface

uses Windows, Messages, SysUtils, Classes, Controls, Contnrs, Forms;

type
  TOnHookWndProc = procedure(Sender: TObject; var Message: TMessage;
    CallWndProc: TWndMethod) of object;

  THookRec = class(TObject)
    Owner: TObject; //can bee nil
    Event: TOnHookWndProc;
  end;

  THookComponent = class(TComponent)
  private
    FActive: Boolean;
    function GetEventCount: Integer;
    function GetRecEventByIndex(Index: Integer): THookRec;
    procedure SetActive(const Value: Boolean);
    procedure SetHookControl(const Value: TWinControl);
  private
    FLoopCallID: Integer;
    FOriginalWndProc: TWndMethod;
    FHookControl: TWinControl;
    FItems: TObjectList;
    property Active: Boolean read FActive write SetActive;
    property Count: Integer read GetEventCount;
    property Items[Index: Integer]: THookRec read GetRecEventByIndex;
  protected
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
    procedure CallNextEvent(var Message: TMessage);
    procedure NewWndProc(var Message: TMessage);
    function IndexOfEvent(aOwner: TObject; aEvent: TOnHookWndProc): Integer;
  public
    Constructor Create(aOwner: TComponent); override;
    Destructor Destroy; override;
    procedure HookWndProc(aOwner: TObject; aHookEvent: TOnHookWndProc);
    procedure UnHookWndProc(aOwner: TObject; aHookEvent: TOnHookWndProc);
    property HookControl: TWinControl read FHookControl write SetHookControl; 
  end;

  THookList = class(TComponent)
  private
    function GetCount: Integer;
    function GetItemByIndex(Index: Integer): THookComponent;
  private
    FItems: TObjectList;
    property Count: Integer read GetCount;
    property Items[Index: Integer]: THookComponent read GetItemByIndex;
//    function IndexOf(aOwner: TComponent; Const aHookControl: TWinControl = nil): Integer;
    function IndexOfHookControl(aHookControl: TWinControl): Integer;
  public
    Constructor Create(aOwner: TComponent); override;
    Destructor Destroy; override;
    procedure HookWndProc(aOwner: TObject; aHookControl: TWinControl; aEvent: TOnHookWndProc);
    procedure UnHookWndProc(aOwner: TObject; aHookControl: TWinControl; aEvent: TOnHookWndProc);
  end;

  procedure gHookWndProcEvent(aOwner: TObject; aHookControl: TWinControl; aEvent: TOnHookWndProc);
  procedure gUnHookWndProcEvent(aOwner: TObject; aHookControl: TWinControl; aEvent: TOnHookWndProc);

implementation

var
  globHookList: THookList;

  procedure gHookWndProcEvent(aOwner: TObject; aHookControl: TWinControl;
    aEvent: TOnHookWndProc);
  begin
    if (aOwner=nil) or (aHookControl=nil) then
      exit;
    if globHookList = nil then
      globHookList := THookList.Create(nil);
    globHookList.HookWndProc(aOwner, aHookControl, aEvent);
  end;
  procedure gUnHookWndProcEvent(aOwner: TObject; aHookControl: TWinControl;
    aEvent: TOnHookWndProc);
  begin
    if globHookList = nil then
      exit;
    globHookList.UnHookWndProc(aOwner, aHookControl, aEvent);
    if globHookList.Count = 0 then
      FreeAndNil(globHookList);  
  end;

{ THookComponent }

procedure THookComponent.CallNextEvent(var Message: TMessage);
var
  vDone: Boolean;
  vIndex: Integer;
begin
  vDone := False;
  vIndex := FLoopCallID;
  Dec(FLoopCallID);
  if (vIndex >= 0) and (vIndex <= Count-1) then
    try
      Items[vIndex].Event(Self, Message, CallNextEvent);
      vDone := True;
    except
    end;

  if not vDone then
    FOriginalWndProc(Message);
end;

constructor THookComponent.Create(aOwner: TComponent);
begin
  inherited;
  FActive := False;
  FLoopCallID := -1;
  FOriginalWndProc := nil;
  FItems := TObjectList.Create;
end;

destructor THookComponent.Destroy;
begin
  Active := False;
  FreeAndNil(FItems);
  inherited;
end;

function THookComponent.GetEventCount: Integer;
begin
  Result := FItems.Count;
end;

function THookComponent.GetRecEventByIndex(Index: Integer): THookRec;
begin
  Result := THookRec(FItems[Index]);
end;

procedure THookComponent.HookWndProc(aOwner: TObject;
  aHookEvent: TOnHookWndProc);
var
  vEvRec: THookRec;
begin
  if not Assigned(aHookEvent) then
    exit;
  if IndexOfEvent(aOwner, aHookEvent) >= 0 then //already seted
    exit;

  if aOwner is TComponent then
    TComponent(aOwner).FreeNotification(Self);

  vEvRec := THookRec.Create;
  vEvRec.Owner := aOwner;
  vEvRec.Event := aHookEvent;
  FItems.Add(vEvRec);

  Active := True;
end;

function THookComponent.IndexOfEvent(aOwner: TObject; aEvent: TOnHookWndProc): Integer;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
    if (@Items[i].Event = @aEvent) and (aOwner = Items[i].Owner) then
      begin
        Result := i;
        exit;
      end;
  Result := -1;
end;

procedure THookComponent.NewWndProc(var Message: TMessage);
begin
  FLoopCallID := Count - 1;
  CallNextEvent(Message);
end;

procedure THookComponent.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;
  if not (Operation = opRemove) then
    exit;
  if AComponent = FHookControl then
    begin
      Active := False;
      FItems.Clear;
      FHookControl := nil;
    end
  else
    UnHookWndProc(AComponent, nil);
end;

procedure THookComponent.SetActive(const Value: Boolean);
begin
  if FActive <> Value then
    begin
      if Value and (not Assigned(FHookControl)) then
        exit;

      FActive := Value;

      if Value then
        begin
          FHookControl.HandleNeeded;

          FOriginalWndProc := FHookControl.WindowProc;
          FHookControl.WindowProc := NewWndProc;
        end
      else
        FHookControl.WindowProc := FOriginalWndProc;
    end;
end;

procedure THookComponent.SetHookControl(const Value: TWinControl);
begin
  if FHookControl <> Value then
    begin
      Active := False;
      if FHookControl <> nil then
        begin
          FItems.Clear;
          FHookControl.RemoveFreeNotification(Self);
        end;

      FHookControl := Value;

      if FHookControl <> nil then
        FHookControl.FreeNotification(Self);
    end;
end;

procedure THookComponent.UnHookWndProc(aOwner: TObject; aHookEvent: TOnHookWndProc);
var
  vDelThis: Boolean;
  i: Integer;
begin
  for i := Count - 1 downto 0 do
    begin
      //vDelThis := False;
      if Assigned(aHookEvent) then
        vDelThis := (@aHookEvent=@Items[i].Event) and (aOwner=Items[i].Owner)
      else
        vDelThis := (aOwner=Items[i].Owner);
      if vDelThis then
        FItems.Delete(i);
    end;
  if Count = 0 then
    Active := False;  
end;

{ THookList }

constructor THookList.Create(aOwner: TComponent);
begin
  inherited;
  FItems := TObjectList.Create;
end;

destructor THookList.Destroy;
begin
  FreeAndNil(FItems);
  inherited;
end;

function THookList.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function THookList.GetItemByIndex(Index: Integer): THookComponent;
begin
  Result := THookComponent(FItems[Index]);
end;

procedure THookList.HookWndProc(aOwner: TObject;
  aHookControl: TWinControl; aEvent: TOnHookWndProc);
var
  vHookCmp: THookComponent;
  vIndex: Integer;
begin
  if (aHookControl = nil) or (aOwner = nil) then
    exit;
  vIndex := IndexOfHookControl(aHookControl);
  if vIndex < 0 then
    begin
      vHookCmp := THookComponent.Create(nil);
      vHookCmp.HookControl := aHookControl;
      FItems.Add(vHookCmp);
    end
  else
    vHookCmp := Items[vIndex];
  vHookCmp.HookWndProc(aOwner, aEvent);
end;

function THookList.IndexOfHookControl(aHookControl: TWinControl): Integer;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
    if Items[i].HookControl = aHookControl then
      begin
        Result := i;
        exit;
      end;
  Result := -1;
end;

procedure THookList.UnHookWndProc(aOwner: TObject; aHookControl: TWinControl;
  aEvent: TOnHookWndProc);
var
  i: Integer;
//  vHookCmp: THookComponent;
begin
  for i := Count - 1 downto 0 do
    if (aHookControl=nil) or (Items[i].HookControl = aHookControl) then
      begin
        Items[i].UnHookWndProc(aOwner, aEvent);
        if Items[i].Count = 0 then
          FItems.Delete(i);
      end;
end;

initialization
finalization
  FreeAndNil(globHookList);
end.

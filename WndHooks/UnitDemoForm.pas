unit UnitDemoForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, UnitHooks;

type
  TFormHookWndDemo = class(TForm)
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Memo1: TMemo;
    chActive: TCheckBox;
    procedure FormDestroy(Sender: TObject);
    procedure chActiveClick(Sender: TObject);
  private
    FActivateHooks: Boolean;
    procedure SetActivateHooks(const Value: Boolean);
    { Private declarations }
  protected
    procedure RerawBorder(Sender: TObject);
    procedure WNDHookProc(Sender: TObject; var Message: TMessage;
      CallWndProc: TWndMethod);
  public
    { Public declarations }
    property ActivateHooks: Boolean read FActivateHooks write SetActivateHooks;
  end;

var
  FormHookWndDemo: TFormHookWndDemo;

implementation

{$R *.dfm}

  procedure _UpdateNCArea(aControl: TWinControl);
  var
    vRect: TRect;
  begin
    vRect := Rect(-2, -2, aControl.Width, aControl.Height);
    RedrawWindow(aControl.Handle, @vRect, 0, RDW_FRAME or RDW_UPDATENOW or RDW_INVALIDATE);
  end;

{ TFormHookWndDemo }

procedure TFormHookWndDemo.SetActivateHooks(const Value: Boolean);
var
  vRect: TRect;
  vHrgn: HRGN;
begin
  if FActivateHooks <> Value then
    begin
      FActivateHooks := Value;
      if Value then
        begin
          gHookWndProcEvent(Self, Edit1, WNDHookProc);
          gHookWndProcEvent(Self, Edit2, WNDHookProc);
          gHookWndProcEvent(Self, Edit3, WNDHookProc);
          gHookWndProcEvent(Self, Memo1, WNDHookProc);
        end
      else
        begin
          gUnHookWndProcEvent(Self, Edit1, WNDHookProc);
          gUnHookWndProcEvent(Self, Edit2, WNDHookProc);
          gUnHookWndProcEvent(Self, Edit3, WNDHookProc);
          gUnHookWndProcEvent(Self, Memo1, WNDHookProc);
        end;
      _UpdateNCArea(Edit1);
      _UpdateNCArea(Edit2);
      _UpdateNCArea(Edit3);
      _UpdateNCArea(Memo1);
    end;
end;

procedure TFormHookWndDemo.WNDHookProc(Sender: TObject;
  var Message: TMessage; CallWndProc: TWndMethod);
begin
  {тут Ваш код выполнится до вызова оригинального WndProc}
  CallWndProc(Message); //Тут выполнится оригинальный WndProc и остальные хуки
  {тут Ваш код выполнится после вызова оригинального WndProc}
  case Message.Msg of
    WM_NCPAINT:
      RerawBorder(THookComponent(Sender).HookControl);
    WM_PAINT:
      RerawBorder(THookComponent(Sender).HookControl);
  end;
end;

procedure TFormHookWndDemo.FormDestroy(Sender: TObject);
begin
  ActivateHooks := False;
end;

procedure TFormHookWndDemo.RerawBorder(Sender: TObject);
var
  vControl: TWinControl;
  vDC: HDC;
  vR: TRect;
  vBrush: HBRUSH;
  vBorderColor: TColor;
begin
  if not ( Sender is TWinControl ) then
    exit;
  vControl := TWinControl(Sender);
  if not vControl.HandleAllocated then
    exit;
  if (GetWindowLong(vControl.Handle, GWL_STYLE) and WS_BORDER = WS_BORDER) then
    exit;
  if vControl=Edit1 then
    vBorderColor := clGreen
  else
    vBorderColor := clRed;
  //============================draw
  vDC := GetWindowDC(vControl.Handle);
  try
    GetWindowRect(vControl.Handle, vR);
    OffsetRect(vR, -vR.Left, -vR.Top);

    vBrush := CreateSolidBrush(ColorToRGB(vBorderColor));
    try
      FrameRect(vDC, vR, vBrush);
    finally
      DeleteObject(vBrush);
    end;
  finally
    ReleaseDC(vControl.Handle, vDC);
  end;
end;

procedure TFormHookWndDemo.chActiveClick(Sender: TObject);
begin
  ActivateHooks := chActive.Checked;
end;

end.

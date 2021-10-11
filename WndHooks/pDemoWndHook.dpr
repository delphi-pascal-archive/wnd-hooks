program pDemoWndHook;

uses
  Forms,
  UnitDemoForm in 'UnitDemoForm.pas' {FormHookWndDemo};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFormHookWndDemo, FormHookWndDemo);
  Application.Run;
end.

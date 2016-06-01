//
// https://github.com/showcode
//

program OTP;

uses
  Forms,
  MainFrm in 'MainFrm.pas' {MainForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.

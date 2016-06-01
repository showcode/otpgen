//
// https://github.com/showcode
//

unit MainFrm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Spin, StdCtrls;

type
  TBytes = array of Byte;

  TMainForm = class(TForm)
    edtKey: TEdit;
    lblSecureKey: TLabel;
    btnNext: TButton;
    lblCounter: TLabel;
    edtCounter: TSpinEdit;
    lblResult: TLabel;
    edtResult: TEdit;
    chkPostIncrement: TCheckBox;
    procedure btnNextClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    function HmacSha1(const Data, Key: TBytes): TBytes;
    function HOTP(const Secret: TBytes; Counter: Cardinal; Digits: Integer = 6): string;
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  IniFiles, Wcrypt2;

const
  DEFAULT_KEY = '3132333435363738393031323334353637383930'; /* Example value from rfc4226 */
  SECTION_TOKEN = 'Token1';
  SECTION_TOKEN_KEY = 'Key';
  SECTION_TOKEN_COUNTER = 'Counter';

function BytesToHex(const Bytes: TBytes): string;
begin
  SetLength(Result, Length(Bytes) * 2);
  BinToHex(Pointer(Bytes), Pointer(Result), Length(Bytes));
end;

function HexToBytes(const S: string): TBytes;
begin
  SetLength(Result, Length(S) div 2);
  HexToBin(Pointer(LowerCase(S)), Pointer(Result), Length(Result));
end;

function BinToBytes(const Data; DataSize: Integer): TBytes;
begin
  SetLength(Result, DataSize);
  Move(Data, Pointer(Result)^, DataSize);
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(ChangeFileExt(Application.ExeName, '.ini'));
  try
    Ini.WriteString(SECTION_TOKEN, SECTION_TOKEN_KEY, edtKey.Text);
    Ini.WriteInteger(SECTION_TOKEN, SECTION_TOKEN_COUNTER, edtCounter.Value);
  finally
    Ini.Free;
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(ChangeFileExt(Application.ExeName, '.ini'));
  try
    edtKey.Text := Ini.ReadString(SECTION_TOKEN, SECTION_TOKEN_KEY, DEFAULT_KEY);
    edtCounter.Value := Ini.ReadInteger(SECTION_TOKEN, SECTION_TOKEN_COUNTER, 0);
  finally
    Ini.Free;
  end;
end;

procedure TMainForm.btnNextClick(Sender: TObject);
var
  Key: TBytes;
begin
  Key := HexToBytes(edtKey.Text);
  edtResult.Text := HOTP(Key, edtCounter.Value);
  if chkPostIncrement.Checked then
    edtCounter.Value := edtCounter.Value + 1;
end;

function TMainForm.HmacSha1(const Data, Key: TBytes): TBytes;
const
  CRYPT_IPSEC_HMAC_KEY = $00000100;
type
  PBlob = ^TBlob;
  TBlob = record Header: BLOBHEADER; Len: Cardinal; Key: array [0..0] of Byte; end;
var
  hProv: HCRYPTPROV;
  hKey: HCRYPTKEY;
  hHmacHash: HCRYPTHASH;
  HmacInfo: HMAC_INFO;
  BlobSize, HashSize: Integer;
  pKeyBlob: PBlob;
begin
  Win32Check(CryptAcquireContext(@hProv, nil, MS_ENHANCED_PROV, PROV_RSA_FULL, CRYPT_VERIFYCONTEXT or CRYPT_NEWKEYSET));
  try
    BlobSize := SizeOf(TBlob) + Length(Key);
    pKeyBlob := AllocMem(BlobSize);
    try
      pKeyBlob.Header.bType := PLAINTEXTKEYBLOB;
      pKeyBlob.Header.bVersion := CUR_BLOB_VERSION;
      pKeyBlob.Header.reserved := 0;
      pKeyBlob.Header.aiKeyAlg := CALG_RC2;
      CopyMemory(@pKeyBlob.Key, Pointer(Key), Length(Key));
      pKeyBlob.Len := Length(Key);
      Win32Check(CryptImportKey(hProv, Pointer(pKeyBlob), BlobSize, 0, CRYPT_IPSEC_HMAC_KEY, @hKey));
      try
        Win32Check(CryptCreateHash(hProv, CALG_HMAC, hKey, 0, @hHmacHash));
        try
          ZeroMemory(@HmacInfo, SizeOf(HmacInfo));
          HmacInfo.HashAlgid := CALG_SHA1;
          Win32Check(CryptSetHashParam(hHmacHash, HP_HMAC_INFO, @HmacInfo, 0));
          Win32Check(CryptHashData(hHmacHash, Pointer(Data), Length(Data), 0));
          Win32Check(CryptGetHashParam(hHmacHash, HP_HASHVAL, nil, @HashSize, 0));
          SetLength(Result, HashSize);
          Win32Check(CryptGetHashParam(hHmacHash, HP_HASHVAL, Pointer(Result), @HashSize, 0));
        finally
          CryptDestroyHash(hHmacHash);
        end;
      finally
        CryptDestroyKey(hKey);
      end;
    finally
      FreeMem(pKeyBlob, BlobSize);
    end;
  finally
    CryptReleaseContext(hProv, 0);
  end;
end;

function TMainForm.HOTP(const Secret: TBytes; Counter: Cardinal; Digits: Integer = 6): string;
const
  DIGITS_POWER: array [0..8] of Integer = (1, 10, 100, 1000, 10000, 100000, 1000000, 10000000, 100000000);
var
  Data, Hash: TBytes;
  Offset, Binary: Integer;
  I: Integer;
begin
  SetLength(Data, 8);
  for I  := Length(Data) - 1 downto 0 do
  begin
    Data[I] := Byte(Counter);
    Counter := Counter shr 8;
  end;
  Hash := HmacSha1(Data, Secret);
  Offset := Hash[High(Hash)] and $0F;
  Binary := $7FFFFFFF and MakeLong(
    MakeWord(Hash[Offset + 3], Hash[Offset + 2]),
    MakeWord(Hash[Offset + 1], Hash[Offset]));
  Binary := Binary mod DIGITS_POWER[Digits];
  Result := IntToStr(Binary);
  if Length(Result) < Digits then
    Result := StringOfChar('0', Digits - Length(Result)) + Result;
end;

end.

//function Sha1(const Data: TBytes): TBytes;
//var
//  hProv: HCRYPTPROV;
//  hHash: HCRYPTHASH;
//  HashSize: Cardinal;
//begin
//  if not CryptAcquireContext(@hProv, nil, nil, PROV_RSA_FULL, 0) then
//    RaiseLastOSError;
//  try
//    if not CryptCreateHash(hProv, CALG_SHA1, 0, 0, @hHash) then
//      RaiseLastOSError;
//    try
//      if not CryptHashData(hHash, Pointer(Data), Length(Data), 0) then
//        RaiseLastOSError;
//      if not CryptGetHashParam(hHash, HP_HASHVAL, nil, @HashSize,0) then
//        RaiseLastOSError;
//      SetLength(Result, HashSize);
//      if not CryptGetHashParam(hHash, HP_HASHVAL, Pointer(Result), @HashSize, 0) then
//        RaiseLastOSError;
//    finally
//      CryptDestroyHash(hHash);
//    end;
//  finally
//    CryptReleaseContext(hProv, 0);
//  end;
//end;
//




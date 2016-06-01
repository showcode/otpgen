object MainForm: TMainForm
  Left = 0
  Top = 0
  BorderStyle = bsSingle
  Caption = 'OTP'
  ClientHeight = 106
  ClientWidth = 468
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  DesignSize = (
    468
    106)
  PixelsPerInch = 96
  TextHeight = 13
  object lblSecureKey: TLabel
    Left = 8
    Top = 20
    Width = 54
    Height = 13
    Caption = 'Secure Key'
  end
  object lblCounter: TLabel
    Left = 8
    Top = 56
    Width = 68
    Height = 13
    Caption = 'Counter Value'
  end
  object lblResult: TLabel
    Left = 176
    Top = 56
    Width = 30
    Height = 13
    Caption = 'Result'
  end
  object edtKey: TEdit
    Left = 80
    Top = 17
    Width = 379
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 0
  end
  object btnNext: TButton
    Left = 385
    Top = 51
    Width = 75
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Next'
    TabOrder = 1
    OnClick = btnNextClick
  end
  object edtCounter: TSpinEdit
    Left = 90
    Top = 53
    Width = 71
    Height = 22
    MaxValue = 0
    MinValue = 0
    TabOrder = 2
    Value = 0
  end
  object edtResult: TEdit
    Left = 240
    Top = 53
    Width = 123
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    Color = clInactiveBorder
    ReadOnly = True
    TabOrder = 3
  end
  object chkPostIncrement: TCheckBox
    Left = 8
    Top = 81
    Width = 97
    Height = 17
    Caption = 'PostIncrement'
    TabOrder = 4
  end
end

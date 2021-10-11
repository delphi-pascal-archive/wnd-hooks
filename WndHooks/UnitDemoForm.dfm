object FormHookWndDemo: TFormHookWndDemo
  Left = 289
  Top = 115
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'FormHookWnd'
  ClientHeight = 167
  ClientWidth = 350
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Edit1: TEdit
    Left = 16
    Top = 16
    Width = 121
    Height = 21
    TabOrder = 0
    Text = 'Edit1'
  end
  object Edit2: TEdit
    Left = 16
    Top = 48
    Width = 121
    Height = 21
    TabOrder = 1
    Text = 'Edit2'
  end
  object Edit3: TEdit
    Left = 16
    Top = 80
    Width = 121
    Height = 21
    TabOrder = 2
    Text = 'Edit3'
  end
  object Memo1: TMemo
    Left = 152
    Top = 16
    Width = 185
    Height = 89
    Lines.Strings = (
      'Memo1')
    TabOrder = 3
  end
  object chActive: TCheckBox
    Left = 16
    Top = 128
    Width = 185
    Height = 17
    Caption = 'Activate wnd hook'
    TabOrder = 4
    OnClick = chActiveClick
  end
end

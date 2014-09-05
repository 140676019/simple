unit ufrmCaptionToolbar;

interface

uses
  Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Types, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TTest = class
  strict private const
    WM_NCUAHDRAWCAPTION = $00AE;
    WM_NCUAHDRAWFRAME = $00AF;
  private
    FCallDefaultProc: Boolean;
    FChangeSizeCalled: Boolean;
    FControl: TWinControl;
    FHandled: Boolean;
    FNeedsUpdate: Boolean; //

    FRegion: HRGN;
    FLeft: integer;
    FTop: integer;
    FWidth: integer;
    FHeight: integer;

    function  GetHandle: HWND; inline;
    function  GetForm: TCustomForm; inline;

    procedure ChangeSize;

    procedure WMNCPaint(var message: TWMNCPaint); message WM_NCPAINT;
    procedure WMNCActivate(var Message: TMessage); message WM_NCACTIVATE;
    procedure WMNCLButtonDown(var Message: TWMNCHitMessage); message WM_NCLBUTTONDOWN;
    procedure WMNCUAHDrawCaption(var Message: TMessage); message WM_NCUAHDRAWCAPTION;
    procedure WMNCUAHDrawFrame(var Message: TMessage); message WM_NCUAHDRAWFRAME;

    procedure WMNCCalcSize(var message: TWMNCCalcSize); message WM_NCCALCSIZE;
    procedure WMWindowPosChanging(var Message: TWMWindowPosChanging); message WM_WINDOWPOSCHANGING;

    procedure WndProc(var message: TMessage);
    procedure CallDefaultProc(var message: TMessage);

  protected
    property Handle: HWND read GetHandle;
    procedure InvalidateNC;
    procedure PaintNC(ARGN: HRGN = 0);
  public
    constructor Create(AOwner: TWinControl);
    destructor Destroy; override;

    property Handled: Boolean read FHandled write FHandled;
    property Control: TWinControl read FControl;
    property Form: TCustomForm read GetForm;
  end;

  TForm11 = class(TForm)
    Button1: TButton;
  private
    FTest: TTest;
  protected
    function DoHandleMessage(var message: TMessage): Boolean;
    procedure WndProc(var Message: TMessage); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  Form11: TForm11;

implementation

{$R *.dfm}

{ TForm11 }

constructor TForm11.Create(AOwner: TComponent);
begin
  FTest := TTest.Create(Self);
  inherited;
end;

destructor TForm11.Destroy;
begin
  inherited;
  FreeAndNil(FTest);
end;

function TForm11.DoHandleMessage(var message: TMessage): Boolean;
begin
  Result := False;
  if not FTest.FCallDefaultProc then
  begin
    FTest.WndProc(message);
    Result := FTest.Handled;
  end;
end;

procedure TForm11.WndProc(var Message: TMessage);
begin
  if not DoHandleMessage(Message) then
    inherited;
end;

procedure TTest.CallDefaultProc(var message: TMessage);
begin
  ///
  ///  ���ÿؼ�Ĭ����Ϣ�������
  ///    Ϊ��ֹ����ѭ�����ã���Ҫʹ��״̬����(FCallDefaultProc)
  ///
  if FCallDefaultProc then
    FControl.WindowProc(message)
  else
  begin
    FCallDefaultProc := True;
    FControl.WindowProc(message);
    FCallDefaultProc := False;
  end;
end;

procedure TTest.ChangeSize;
var
  hTmp: HRGN;
begin
  /// ����������ʽ
  FChangeSizeCalled := True;
  try
    hTmp := FRegion;
    try
      /// ���� ����Ϊ3�ľ�������
      ///    ���������ʵ�ֲ��������Ĵ���������ͨ��bmp������������
      ///
      ///  ע��
      ///    HRGN �������ͼ�ζ�����window�������Դ�����ͷŻ�����ڴ�й¶��
      ///    ������㶮�á�
      FRegion := CreateRoundRectRgn(0, 0, FWidth, FHeight, 3, 3);
      SetWindowRgn(Handle, FRegion, True);
    finally
      if hTmp <> 0 then
        DeleteObject(hTmp); // �ͷ���Դ
   end;
  finally
    FChangeSizeCalled := False;
  end;
end;

constructor TTest.Create(AOwner: TWinControl);
begin
  FControl := AOwner;
  FNeedsUpdate := True;
  FRegion := 0;
  FChangeSizeCalled := False;
  FCallDefaultProc := False;

  FWidth := FControl.Width;
  FHeight := FControl.Height;
end;

destructor TTest.Destroy;
begin
  if FRegion <> 0 then
    DeleteObject(FRegion);
  inherited;
end;

function TTest.GetForm: TCustomForm;
begin
  Result := TCustomForm(Control);
end;

function TTest.GetHandle: HWND;
begin
  if FControl.HandleAllocated then
    Result := FControl.Handle
  else
    Result := 0;
end;

procedure TTest.InvalidateNC;
begin
  if FControl.HandleAllocated then
    SendMessage(Handle, WM_NCPAINT, 1, 0);
end;

procedure TTest.PaintNC(ARGN: HRGN = 0);
var
  DC: HDC;
  Flags: cardinal;
  hb: HBRUSH;
  P: TPoint;
  r: TRect;
begin
  Flags := DCX_CACHE or DCX_CLIPSIBLINGS or DCX_WINDOW or DCX_VALIDATE;
  if (ARgn = 1) then
    DC := GetDCEx(Handle, 0, Flags)
  else
    DC := GetDCEx(Handle, ARgn, Flags or DCX_INTERSECTRGN);

  if DC <> 0 then
  begin
    P := Point(0, 0);
    Windows.ClientToScreen(Handle, P);
    Windows.GetWindowRect(Handle, R);
    P.X := P.X - R.Left;
    P.Y := P.Y - R.Top;
    Windows.GetClientRect(Handle, R);

    ExcludeClipRect(DC, P.X, P.Y, R.Right - R.Left + P.X, R.Bottom - R.Top + P.Y);

    GetWindowRect(handle, r);
    OffsetRect(R, -R.Left, -R.Top);

    hb := CreateSolidBrush($00bf7b18);
    FillRect(dc, r, hb);
    DeleteObject(hb);

    SelectClipRgn(DC, 0);

    ReleaseDC(Handle, dc);
  end;
end;

procedure TTest.WMNCActivate(var Message: TMessage);
begin
  //FFormActive := Message.WParam > 0;
  Message.Result := 1;
  InvalidateNC;
  Handled := True;
end;

procedure TTest.WMNCCalcSize(var message: TWMNCCalcSize);
const
  SIZE_BORDER = 5;
  SIZE_CAPTION = 28;
begin
  // �ı�߿�ߴ�
  with TWMNCCALCSIZE(Message).CalcSize_Params^.rgrc[0] do
  begin
    Inc(Left, SIZE_BORDER);
    Inc(Top, SIZE_CAPTION);
    Dec(Right, SIZE_BORDER);
    Dec(Bottom, SIZE_BORDER);
  end;
  Message.Result := 0;
  Handled := True;
end;

procedure TTest.WMWindowPosChanging(var Message: TWMWindowPosChanging);
var
  bChanged: Boolean;
begin
  /// ���ⲿ���ȴ�����Ϣ,�������Ĭ�ϵĿ���
  CallDefaultProc(TMessage(Message));

  Handled := True;
  bChanged := False;

  /// ��ֹǶ��
  if FChangeSizeCalled then
    Exit;

  /// �����������
  ///   �������ߴ��е���ʱ��Ҫ�������ɴ����������
  ///
  if (Message.WindowPos^.flags and SWP_NOSIZE = 0) or
     (Message.WindowPos^.flags and SWP_NOMOVE = 0) then
  begin
    if (Message.WindowPos^.flags and SWP_NOMOVE = 0) then
    begin
      FLeft := Message.WindowPos^.x;
      FTop := Message.WindowPos^.y;
    end;
    if (Message.WindowPos^.flags and SWP_NOSIZE = 0) then
    begin
      bChanged := ((Message.WindowPos^.cx <> FWidth) or (Message.WindowPos^.cy <> FHeight)) and
                 (Message.WindowPos^.flags and SWP_NOSIZE = 0);
      FWidth := Message.WindowPos^.cx;
      FHeight := Message.WindowPos^.cy;
    end;
  end;

  if (Message.WindowPos^.flags and SWP_FRAMECHANGED  <> 0) then
    bChanged := True;

  // ���е������ػ洦��
  if bChanged then
  begin
    ChangeSize;
    InvalidateNC;
  end;
end;

procedure TTest.WMNCLButtonDown(var Message: TWMNCHitMessage);
begin
  inherited;

  if (Message.HitTest = HTCLOSE) or (Message.HitTest = HTMAXBUTTON) or
     (Message.HitTest = HTMINBUTTON) or (Message.HitTest = HTHELP) then
  begin
    //FPressedButton := Message.HitTest;
    InvalidateNC;
    Message.Result := 0;
    Message.Msg := WM_NULL;
    Handled := True;
  end;
end;

procedure TTest.WMNCPaint(var message: TWMNCPaint);
begin
  PaintNC(message.RGN);
  Handled := True;
end;

procedure TTest.WMNCUAHDrawCaption(var Message: TMessage);
begin
  ///  �����Ϣ����winxp�²��������ڲ�Bug����ֱ�Ӷ�������Ϣ
  Handled := True;
end;

procedure TTest.WMNCUAHDrawFrame(var Message: TMessage);
begin
  ///  �����Ϣ����winxp�²��������ڲ�Bug����ֱ�Ӷ�������Ϣ
  Handled := True;
end;

procedure TTest.WndProc(var message: TMessage);
begin
  FHandled := False;
  Dispatch(message);
end;

end.

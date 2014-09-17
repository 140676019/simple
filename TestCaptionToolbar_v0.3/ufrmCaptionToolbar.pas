unit ufrmCaptionToolbar;

interface

uses
  Messages, SysUtils, Variants, Types, Controls, Forms, Dialogs, StdCtrls,
  ExtCtrls,
  ComCtrls,
  Windows,  // �����Ԫ���� ComCtrls �ĺ��棬HITTEST �Ķ�����������Сд��������ĺܲ�����
  Classes, Graphics,
  pngimage, Actions, ActnList, ToolWin, Vcl.ImgList, Vcl.Buttons;

type
  TFormButtonKind = (fbkMin, fbkMax, fbkRestore, fbkClose, fbkHelp);
  TSkinIndicator = (siInactive, siHover, siPressed, siSelected, siHoverSelected);

  TTest = class
  strict private
  const
    WM_NCUAHDRAWCAPTION = $00AE;
  private
    FCallDefaultProc: Boolean;
    FChangeSizeCalled: Boolean;
    FControl: TWinControl;
    FHandled: Boolean;

    FRegion: HRGN;
    FLeft: integer;
    FTop: integer;
    FWidth: integer;
    FHeight: integer;

    /// ����ͼ��
    FIcon: TIcon;
    FIconHandle: HICON;

    // ����λ�ã�ֻ�����ص�λ�ã������н���ϵͳ����
    FPressedHit: Integer;     // ʵ�ʰ��µ�λ��, 
    FHotHit: integer;         // ��¼�ϴεĲ���λ�� 

    // skin
    //  �������Ӧ������������Ϊ����һ������Ӧ�������д��塣
    FSkinData: TBitmap;
    procedure DrawButton(DC: HDC; AKind: TFormButtonKind; AState: TSkinIndicator; const R: TRect);

    function GetHandle: HWND; inline;
    function GetForm: TCustomForm; inline;
    function GetFrameSize: TRect;
    function GetCaptionRect(AMaxed: Boolean): TRect; inline;
    function GetCaption: string;
    function GetIcon: TIcon;
    function GetIconFast: TIcon;

    procedure ChangeSize;
    function  NormalizePoint(P: TPoint): TPoint;
    function  HitTest(P: TPoint):integer;
    procedure Maximize;
    procedure Minimize;

    // ��һ�� ʵ�ֻ��ƻ���
    procedure WMNCPaint(var message: TWMNCPaint); message WM_NCPAINT;
    procedure WMNCActivate(var message: TMessage); message WM_NCACTIVATE;
    procedure WMNCUAHDrawCaption(var message: TMessage); message WM_NCUAHDRAWCAPTION;

    // �ڶ��� ���ƴ�����ʽ
    procedure WMNCCalcSize(var message: TWMNCCalcSize); message WM_NCCALCSIZE;
    procedure WMWindowPosChanging(var message: TWMWindowPosChanging); message WM_WINDOWPOSCHANGING;

    // ������ ���Ʊ������ڲ��ؼ�
    procedure WMEraseBkgnd(var message: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure WMPaint(var message: TWMPaint); message WM_PAINT;

    // ������ ���ư�ť״̬
    procedure WMNCHitTest(var Message: TWMNCHitTest); message WM_NCHITTEST;
    procedure WMNCLButtonDown(var message: TWMNCHitMessage); message WM_NCLBUTTONDOWN;
    procedure WMNCLButtonUp(var Message: TWMNCHitMessage); message WM_NCLBUTTONUP;
    procedure WMNCMouseMove(var Message: TWMNCMouseMove); message WM_NCMOUSEMOVE;

    procedure WMSetText(var Message: TMessage); message WM_SETTEXT;

    procedure WndProc(var message: TMessage);
    procedure CallDefaultProc(var message: TMessage);

  protected
    property  Handle: HWND read GetHandle;
    procedure InvalidateNC;
    procedure PaintNC(DC: HDC);
    procedure PaintBackground(DC: HDC);
    procedure Paint(DC: HDC);

  public
    constructor Create(AOwner: TWinControl);
    destructor Destroy; override;

    property Handled: Boolean read FHandled write FHandled;
    property Control: TWinControl read FControl;
    property Form: TCustomForm read GetForm;

  end;

  TForm11 = class(TForm)
    Button1: TButton;
    Shape1: TShape;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;
    ToolBar1: TToolBar;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    ActionList1: TActionList;
    Action1: TAction;
    Action2: TAction;
    Action3: TAction;
    ImageList1: TImageList;
    procedure Action1Execute(Sender: TObject);
    procedure Action2Execute(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
  private
    FTest: TTest;
  protected
    function DoHandleMessage(var message: TMessage): Boolean;
    procedure WndProc(var message: TMessage); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

  Res = class
    class procedure LoadGraphic(const AName: string; AGraphic: TGraphic);
    class procedure LoadBitmap(const AName: string; AGraphic: TBitmap);
  end;

var
  Form11: TForm11;

implementation

const
  SKINCOLOR_BAKCGROUND  = $00BF7B18;  // ����ɫ
  SKINCOLOR_BTNHOT      = $00F2D5C2;  // Hot ����״̬
  SKINCOLOR_BTNPRESSED  = $00E3BDA3;  // ����״̬
  SIZE_SYSBTN: TSize    = (cx: 29; cy: 18);
  SIZE_FRAME: TRect     = (Left: 4; Top: 28; Right: 5; Bottom: 5); // ����߿�ĳߴ�
  SPACE_AREA            = 3;          // ��������֮����
  SIZE_RESICON          = 16;         // ��Դ��ͼ��Ĭ�ϳߴ�


{$R *.dfm}
{$R MySkin.RES}

type
  TacWinControl = class(TWinControl);

function BuildRect(L, T, W, H: Integer): TRect; inline;
begin
  Result := Rect(L, T, L + W, T + H);
end;

procedure DrawTransparentBitmap(Source: TBitmap; sx, sy: Integer; Destination: HDC;
  const dX, dY: Integer;  w, h: Integer; const Opacity: Byte = 255); overload;
var
  BlendFunc: TBlendFunction;
begin
  BlendFunc.BlendOp := AC_SRC_OVER;
  BlendFunc.BlendFlags := 0;
  BlendFunc.SourceConstantAlpha := Opacity;

  if Source.PixelFormat = pf32bit then
    BlendFunc.AlphaFormat := AC_SRC_ALPHA
  else
    BlendFunc.AlphaFormat := 0;

  AlphaBlend(Destination, dX, dY, w, h, Source.Canvas.Handle, sx, sy, w, h, BlendFunc);
end;

class procedure Res.LoadBitmap(const AName: string; AGraphic: TBitmap);
var
  cPic: TPngImage;
  cBmp: TBitmap;
begin
  cBmp := AGraphic;
  cPic := TPngImage.Create;
  try
    cBmp.PixelFormat := pf32bit;
    cBmp.alphaFormat := afIgnored;
    try
      LoadGraphic(AName, cPic);
      cBmp.SetSize(cPic.Width, cPic.Height);
      cBmp.Canvas.Brush.Color := clBlack;
      cBmp.Canvas.FillRect(Rect(0, 0, cBmp.Width, cBmp.Height));
      cBmp.Canvas.Draw(0, 0, cPic);
    except
      // �������ͼƬ
    end;
  finally
    cPic.Free;
  end;
end;

class procedure Res.LoadGraphic(const AName: string; AGraphic: TGraphic);
var
  cStream: TResourceStream;
  h: THandle;
begin
  ///
  /// ����ͼƬ��Դ
  h := HInstance;
  cStream := TResourceStream.Create(h, AName, RT_RCDATA);
  try
    AGraphic.LoadFromStream(cStream);
  finally
    cStream.Free;
  end;
end;

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

procedure TForm11.Action1Execute(Sender: TObject);
begin
  Tag := Tag + 1;
  Caption := format('test %d', [Tag]);
end;

procedure TForm11.Action2Execute(Sender: TObject);
begin
  if Shape1.Shape <> High(TShapeType) then
    Shape1.Shape := Succ(Shape1.Shape)
  else
    Shape1.Shape := low(TShapeType);
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

procedure TForm11.SpeedButton1Click(Sender: TObject);
begin
  Caption := format('test %d', [1]);
end;

procedure TForm11.WndProc(var message: TMessage);
begin
  if not DoHandleMessage(Message) then
    inherited;
end;

procedure TTest.CallDefaultProc(var message: TMessage);
begin
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
  /// ���ô��������ʽ
  FChangeSizeCalled := True;
  try
    hTmp := FRegion;
    try
      /// �����������3�ĵ���
      FRegion := CreateRoundRectRgn(0, 0, FWidth, FHeight, 3, 3);
      SetWindowRgn(Handle, FRegion, True);
    finally
      if hTmp <> 0 then
        DeleteObject(hTmp);
    end;
  finally
    FChangeSizeCalled := False;
  end;
end;

function TTest.NormalizePoint(P: TPoint): TPoint;
var
  rWindowPos, rClientPos: TPoint;
begin
  rWindowPos := Point(FLeft, FTop);
  rClientPos := Point(0, 0);
  ClientToScreen(Handle, rClientPos);
  Result := P;
  ScreenToClient(Handle, Result);
  Inc(Result.X, rClientPos.X - rWindowPos.X);
  Inc(Result.Y, rClientPos.Y - rWindowPos.Y);
end;

function TTest.HitTest(P: TPoint):integer;
var
  bMaxed: Boolean;
  r: TRect;
  rCaptionRect: TRect;
  rFrame: TRect;
begin
  Result := HTNOWHERE;

  ///
  /// ���λ��
  ///
  rFrame := GetFrameSize;
  if p.Y > rFrame.Top then
    Exit;

  ///
  ///  ֻ���Ĵ��尴ť����
  ///
  bMaxed := IsZoomed(Handle);
  rCaptionRect := GetCaptionRect(bMaxed);
  if PtInRect(rCaptionRect, p) then
  begin
    r.Right := rCaptionRect.Right - 1;
    r.Top := 0;
    if bMaxed then
      r.Top := rCaptionRect.Top;
    r.Top := r.Top + (rFrame.Top - r.Top - SIZE_SYSBTN.cy) div 2;
    r.Left := r.Right - SIZE_SYSBTN.cx;
    r.Bottom := r.Top + SIZE_SYSBTN.cy;

    ///
    /// ʵ�ʻ��Ƶİ�ť������������û����
    ///
    if (P.Y >= r.Top) and (p.Y <= r.Bottom) and (p.X <= r.Right) then
    begin
      if (P.X >= r.Left) then
        Result := HTCLOSE
      else if p.X >= (r.Left - SIZE_SYSBTN.cx) then
        Result := HTMAXBUTTON
      else if p.X >= (r.Left - SIZE_SYSBTN.cx * 2) then
        Result := HTMINBUTTON;
    end;
  end;
end;

constructor TTest.Create(AOwner: TWinControl);
begin
  FControl := AOwner;
  FRegion := 0;
  FChangeSizeCalled := False;
  FCallDefaultProc := False;

  FWidth := FControl.Width;
  FHeight := FControl.Height;
  FIcon := nil;
  FIconHandle := 0;

  // ������Դ
  FSkinData := TBitmap.Create;
  Res.LoadBitmap('MySkin', FSkinData);
end;

destructor TTest.Destroy;
begin
  FIconHandle := 0;
  if FSkinData <> nil then
    FreeAndNil(FSkinData);
  if FIcon <> nil then
    FreeAndNil(FIcon);
  if FRegion <> 0 then
    DeleteObject(FRegion);
  inherited;
end;

procedure TTest.DrawButton(DC: HDC; AKind: TFormButtonKind; AState: TSkinIndicator; const R: TRect);
var
  hB: HBRUSH;
  iColor: Cardinal;
  rSrcOff: TPoint;
  x, y: integer;
begin
  /// ���Ʊ���
  case AState of
    siHover         : iColor := SKINCOLOR_BTNHOT;
    siPressed       : iColor := SKINCOLOR_BTNPRESSED;
    siSelected      : iColor := SKINCOLOR_BTNPRESSED;
    siHoverSelected : iColor := SKINCOLOR_BTNHOT;
  else                iColor := SKINCOLOR_BAKCGROUND;
  end;
  hB := CreateSolidBrush(iColor);
  FillRect(DC, R, hB);
  DeleteObject(hB);

  /// ����ͼ��
  rSrcOff := Point(SIZE_RESICON * ord(AKind), 0);
  x := R.Left + (R.Right - R.Left - SIZE_RESICON) div 2;
  y := R.Top + (R.Bottom - R.Top - SIZE_RESICON) div 2;
  DrawTransparentBitmap(FSkinData, rSrcOff.X, rSrcOff.Y, DC, x, y, SIZE_RESICON, SIZE_RESICON);
end;

function TTest.GetFrameSize: TRect;
begin
  Result := SIZE_FRAME;
end;

function TTest.GetCaptionRect(AMaxed: Boolean): TRect;
var
  rFrame: TRect;
begin
  rFrame := GetFrameSize;
  // ���״̬���״���
  if AMaxed then
    Result := Rect(8, 8, FWidth - 9 , rFrame.Top)
  else
    Result := Rect(rFrame.Left, 3, FWidth - rFrame.right, rFrame.Top);
end;

function TTest.GetCaption: string;
var
  Buffer: array [0..255] of Char;
  iLen: integer;
begin
  if Handle <> 0 then
  begin
    iLen := GetWindowText(Handle, Buffer, Length(Buffer));
    SetString(Result, Buffer, iLen);
  end
  else
    Result := '';
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

function TTest.GetIcon: TIcon;
var
  IconX, IconY: integer;
  TmpHandle: THandle;
  Info: TWndClassEx;
  Buffer: array [0 .. 255] of Char;
begin
  ///
  /// ��ȡ��ǰform��ͼ��
  /// ���ͼ���App��ͼ���ǲ�ͬ��
  ///
  TmpHandle := THandle(SendMessage(Handle, WM_GETICON, ICON_SMALL, 0));
  if TmpHandle = 0 then
    TmpHandle := THandle(SendMessage(Handle, WM_GETICON, ICON_BIG, 0));

  if TmpHandle = 0 then
  begin
    { Get instance }
    GetClassName(Handle, @Buffer, SizeOf(Buffer));
    FillChar(Info, SizeOf(Info), 0);
    Info.cbSize := SizeOf(Info);

    if GetClassInfoEx(GetWindowLong(Handle, GWL_HINSTANCE), @Buffer, Info) then
    begin
      TmpHandle := Info.hIconSm;
      if TmpHandle = 0 then
        TmpHandle := Info.HICON;
    end
  end;

  if FIcon = nil then
    FIcon := TIcon.Create;

  if TmpHandle <> 0 then
  begin
    IconX := GetSystemMetrics(SM_CXSMICON);
    if IconX = 0 then
      IconX := GetSystemMetrics(SM_CXSIZE);
    IconY := GetSystemMetrics(SM_CYSMICON);
    if IconY = 0 then
      IconY := GetSystemMetrics(SM_CYSIZE);
    FIcon.Handle := CopyImage(TmpHandle, IMAGE_ICON, IconX, IconY, 0);
    FIconHandle := TmpHandle;
  end;

  Result := FIcon;
end;

function TTest.GetIconFast: TIcon;
begin
  if (FIcon = nil) or (FIconHandle = 0) then
    Result := GetIcon
  else
    Result := FIcon;
end;

procedure TTest.InvalidateNC;
begin
  if FControl.HandleAllocated then
    SendMessage(Handle, WM_NCPAINT, 1, 0);
end;

procedure TTest.Maximize;
begin
  if Handle <> 0 then
  begin
    FPressedHit := 0;
    FHotHit := 0;
    if IsZoomed(Handle) then
      SendMessage(Handle, WM_SYSCOMMAND, SC_RESTORE, 0)
    else
      SendMessage(Handle, WM_SYSCOMMAND, SC_MAXIMIZE, 0);
  end;
end;

procedure TTest.Minimize;
begin
  if Handle <> 0 then
  begin
    FPressedHit := 0;
    FHotHit := 0;
    if IsIconic(Handle) then
      SendMessage(Handle, WM_SYSCOMMAND, SC_RESTORE, 0)
    else
      SendMessage(Handle, WM_SYSCOMMAND, SC_MINIMIZE, 0);
   end;
end;

procedure TTest.PaintNC(DC: HDC);
const
  HITVALUES: array [TFormButtonKind] of integer = (HTMINBUTTON, HTMAXBUTTON, HTMAXBUTTON, HTCLOSE, HTHELP);

  function GetBtnState(AKind: TFormButtonKind): TSkinIndicator;
  begin
    if (FPressedHit = FHotHit) and (FPressedHit = HITVALUES[AKind]) then
      Result := siPressed
    else if FHotHit = HITVALUES[AKind] then
      Result := siHover
    else
      Result := siInactive;
  end;

var
  hB: HBRUSH;
  rFrame: TRect;
  rButton: TRect;
  SaveIndex: integer;
  bMaxed: Boolean;
  rCaptionRect : TRect;
  sData: string;
  Flag: Cardinal;
  SaveColor: cardinal;
begin
  SaveIndex := SaveDC(DC);
  try
    bMaxed := IsZoomed(Handle);

    // �۳��ͻ�����
    rFrame := GetFrameSize;
    ExcludeClipRect(DC, rFrame.Left, rFrame.Top, FWidth - rFrame.Right, FHeight - rFrame.Bottom);

    ///
    ///  ��������
    ///
    rCaptionRect := GetCaptionRect(bMaxed);

    // ����������屳��
    hB := CreateSolidBrush(SKINCOLOR_BAKCGROUND);
    FillRect(DC, Rect(0, 0, FWidth, FHeight), hB);
    DeleteObject(hB);

    /// ���ƴ���ͼ��
    rButton := BuildRect(rCaptionRect.Left + 2, rCaptionRect.Top, GetSystemMetrics(SM_CXSMICON), GetSystemMetrics(SM_CYSMICON));
    rButton.Top := rButton.Top + (rFrame.Top - rButton.Bottom) div 2;
    DrawIconEx(DC, rButton.Left, rButton.Top, GetIconFast.Handle, 0, 0, 0, 0, DI_NORMAL);

    rCaptionRect.Left := rButton.Right + 5; // ǰ������

    /// ���ƴ��尴ť����
    rButton.Right := rCaptionRect.Right - 1;
    rButton.Top := 0;
    if bMaxed then
      rButton.Top := rCaptionRect.Top;
    rButton.Top := rButton.Top + (rFrame.Top - rButton.Top - SIZE_SYSBTN.cy) div 2;
    rButton.Left := rButton.Right - SIZE_SYSBTN.cx;
    rButton.Bottom := rButton.Top + SIZE_SYSBTN.cy;
    DrawButton(Dc, fbkClose, GetBtnState(fbkClose), rButton);

    OffsetRect(rButton, - SIZE_SYSBTN.cx, 0);
    if bMaxed then
      DrawButton(Dc, fbkRestore, GetBtnState(fbkRestore), rButton)
    else
      DrawButton(Dc, fbkMax, GetBtnState(fbkMax), rButton);

    OffsetRect(rButton, - SIZE_SYSBTN.cx, 0);
    DrawButton(Dc, fbkMin, GetBtnState(fbkMin), rButton);

    rCaptionRect.Right := rButton.Left - 3; // �󲿿ճ�

    /// ����Caption
    sData :=  GetCaption;
    SetBkMode(DC, TRANSPARENT);
    SaveColor := SetTextColor(DC, $00FFFFFF);

    Flag := DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX;
    DrawTextEx(DC, PChar(sData), Length(sData), rCaptionRect, Flag, nil);
    SetTextColor(DC, SaveColor);
  finally
    RestoreDC(DC, SaveIndex);
  end;
end;

procedure TTest.PaintBackground(DC: HDC);
var
  hB: HBRUSH;
  R: TRect;
begin
  GetClientRect(Handle, R);
  hB := CreateSolidBrush($00F0F0F0);
  FillRect(DC, R, hB);
  DeleteObject(hB);
end;

procedure TTest.Paint(DC: HDC);
begin
  // PaintBackground(DC);
  // TODO -cMM: TTest.Paint default body inserted
end;

procedure TTest.WMEraseBkgnd(var message: TWMEraseBkgnd);
var
  DC: HDC;
  SaveIndex: integer;
begin
  DC := Message.DC;
  if DC <> 0 then
  begin
    SaveIndex := SaveDC(DC);
    PaintBackground(DC);
    RestoreDC(DC, SaveIndex);
  end;

  Handled := True;
  Message.Result := 1;
end;

procedure TTest.WMNCActivate(var message: TMessage);
begin
  // FFormActive := Message.WParam > 0;
  Message.Result := 1;
  InvalidateNC;
  Handled := True;
end;

procedure TTest.WMNCCalcSize(var message: TWMNCCalcSize);
var
  R: TRect;
begin
  // �ı�߿�ߴ�
  R := GetFrameSize;
  with TWMNCCalcSize(Message).CalcSize_Params^.rgrc[0] do
  begin
    Inc(Left, R.Left);
    Inc(Top, R.Top);
    Dec(Right, R.Right);
    Dec(Bottom, R.Bottom);
  end;
  Message.Result := 0;
  Handled := True;
end;

procedure TTest.WMNCHitTest(var Message: TWMNCHitTest);
var
  P: TPoint;
  iHit: integer;
begin
  // ��Ҫ��λ��ת����ʵ�ʴ���λ��
  P := NormalizePoint(Point(Message.XPos, Message.YPos));

  // ��ȡ λ��
  // ֻ�Լ��������������ϵͳ����
  iHit := HitTest(p);
  if FHotHit > HTNOWHERE then
  begin
    Message.Result := iHit;
    Handled := True;            // ������ɣ����ٽ���ϵͳ����
  end;
  
  // ��Ӧ��껬���������֪ͨ�ǿͻ����ػ�
  if iHit <> FHotHit then
  begin
    FHotHit := iHit;
    InvalidateNC;
  end;
end;

procedure TTest.WMWindowPosChanging(var message: TWMWindowPosChanging);
var
  bChanged: Boolean;
begin
  CallDefaultProc(TMessage(Message));

  Handled := True;
  bChanged := False;

  /// ��ֹǶ��
  if FChangeSizeCalled then
    Exit;

  if (Message.WindowPos^.flags and SWP_NOSIZE = 0) or (Message.WindowPos^.flags and SWP_NOMOVE = 0) then
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

  if (Message.WindowPos^.flags and SWP_FRAMECHANGED <> 0) then
    bChanged := True;

  if bChanged then
  begin
    ChangeSize;
    InvalidateNC;
  end;
end;

procedure TTest.WMNCLButtonDown(var message: TWMNCHitMessage);
var
  iHit: integer;
begin
  inherited;

  iHit := HTNOWHERE;
  if (Message.HitTest = HTCLOSE) or (Message.HitTest = HTMAXBUTTON) or (Message.HitTest = HTMINBUTTON) or
    (Message.HitTest = HTHELP) then
  begin
    iHit := Message.HitTest;
    Message.Result := 0;
    Message.Msg := WM_NULL;
    Handled := True;
  end;

  if iHit <> FPressedHit then
  begin
    FPressedHit := iHit;
    InvalidateNC;
  end;
end;

procedure TTest.WMNCLButtonUp(var Message: TWMNCHitMessage);
var
  iWasHit: Integer;
begin
  iWasHit := FPressedHit;
  if iWasHit <> HTNOWHERE then
  begin
    FPressedHit := HTNOWHERE;
    //InvalidateNC;

    if iWasHit = FHotHit then
    begin
      case Message.HitTest of
        HTCLOSE     : SendMessage(Handle, WM_SYSCOMMAND, SC_CLOSE, 0);
        HTMAXBUTTON : Maximize;
        HTMINBUTTON : Minimize;
        HTHELP      : SendMessage(Handle, WM_SYSCOMMAND, SC_CONTEXTHELP, 0);
      end;

      Message.Result := 0;
      Message.Msg := WM_NULL;
      Handled := True;
    end;
  end;
end;

procedure TTest.WMNCMouseMove(var Message: TWMNCMouseMove);
begin
  if (FPressedHit <> HTNOWHERE) and (FPressedHit <> Message.HitTest) then
    FPressedHit := HTNOWHERE;
end;

procedure TTest.WMSetText(var Message: TMessage);
begin
  CallDefaultProc(Message);
  InvalidateNC;
  Handled := true;
end;

procedure TTest.WMNCPaint(var message: TWMNCPaint);
var
  DC: HDC;
begin
  DC := GetWindowDC(Control.Handle);
  PaintNC(DC);
  ReleaseDC(Handle, DC);
  Handled := True;
end;

procedure TTest.WMNCUAHDrawCaption(var message: TMessage);
begin
  /// �����Ϣ����winxp�²��������ڲ�Bug����ֱ�Ӷ�������Ϣ
  Handled := True;
end;

procedure TTest.WMPaint(var message: TWMPaint);
var
  DC, hPaintDC: HDC;
  cBuffer: TBitmap;
  PS: TPaintStruct;
begin
  ///
  /// ���ƿͻ�����
  ///
  DC := Message.DC;

  hPaintDC := DC;
  if DC = 0 then
    hPaintDC := BeginPaint(Handle, PS);

  if DC = 0 then
  begin
    /// ����ģʽ���ƣ�������˸
    cBuffer := TBitmap.Create;
    try
      cBuffer.SetSize(FWidth, FHeight);
      PaintBackground(cBuffer.Canvas.Handle);
      Paint(cBuffer.Canvas.Handle);
      /// ֪ͨ�ӿؼ����л���
      /// ��Ҫ��Щͼ�οؼ����ػ��ƣ���TShape��������ͣ����Form�ϵ�ͼ��ؼ��޷�������ʾ
      if Control is TWinControl then
        TacWinControl(Control).PaintControls(cBuffer.Canvas.Handle, nil);
      BitBlt(hPaintDC, 0, 0, FWidth, FHeight, cBuffer.Canvas.Handle, 0, 0, SRCCOPY);
    finally
      cBuffer.Free;
    end;
  end
  else
  begin
    Paint(hPaintDC);
    // ֪ͨ�ӿؼ��ػ�
    if Control is TWinControl then
      TacWinControl(Control).PaintControls(hPaintDC, nil);
  end;

  if DC = 0 then
    EndPaint(Handle, PS);

  Handled := True;
end;

procedure TTest.WndProc(var message: TMessage);
begin
  FHandled := False;
  Dispatch(message);
end;

end.

unit uFormSkins;

interface

uses
  Classes, windows, Controls, Graphics, Forms, messages, pngimage, Types, ImgList;

const
  WM_NCUAHDRAWCAPTION = $00AE;

  CKM_ADD             = WM_USER + 1;  // ���ӱ�������λ��

  HTCUSTOM = 100; //HTHELP + 1;              /// �Զ�������ID
  HTCAPTIONTOOLBAR = HTCUSTOM + 1;    /// ���⹤������

type
  TskForm = class;

  TFormButtonKind = (fbkMin, fbkMax, fbkRestore, fbkClose, fbkHelp);
  TSkinIndicator = (siInactive, siHover, siPressed, siSelected, siHoverSelected);

  TFormCaptionPlugin = class
  private
    FBorder: TRect;
    FOwner: TskForm;
    FVisible: Boolean;

  protected
    procedure Paint(DC: HDC); virtual; abstract;
    function  CalcSize: TRect; virtual; abstract;

    procedure Invalidate;
    procedure Update;
  public
    constructor Create(AOwner: TskForm); virtual;

    property Border: TRect read FBorder;
    property Visible: Boolean read FVisible;
  end;


  TcpToolButton = record
    Action: TBasicAction;
    ImageIndex: Integer;  // ���ǵ����⹦��ͼ���ʵ�ʹ���������ʹ�ò�ͬͼ��������ֿ�ͼ������
  end;

  TcpToolbar = class(TFormCaptionPlugin)
  private
    FItems: array of TcpToolButton;
    FCount: Integer;

    // ���Ǳ������Ƚ����⣬����ʹ�õ��Ǵ��������ͼ����Ҫ���ĸ����ϴ�������
    FImages: TCustomImageList;

  protected
    // ���ư�ť��ʽ
    procedure Paint(DC: HDC); override;
    // ����ʵ��ռ�óߴ�
    function  CalcSize: TRect; override;

  public
    procedure Add(Action: TBasicAction; AImageIndex: Integer = -1);
    procedure Delete(Index: Integer);
    function  IndexOf(Action: TBasicAction): Integer;

    property Images: TCustomImageList read FImages write FImages;
  end;


  TskForm = class
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

    // ���λ��״̬��ֻ�����ص�λ�ã������н���ϵͳ����
    FPressedHit: Integer;     // ʵ�ʰ��µ�λ��
    FHotHit: integer;         // ��¼�ϴεĲ���λ��

    FToolbar: TcpToolbar;

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
    procedure WMNCLButtonDown(var message: TWMNCHitMessage); message WM_NCLBUTTONDOWN;
    procedure WMNCUAHDrawCaption(var message: TMessage); message WM_NCUAHDRAWCAPTION;

    // �ڶ��� ���ƴ�����ʽ
    procedure WMNCCalcSize(var message: TWMNCCalcSize); message WM_NCCALCSIZE;
    procedure WMWindowPosChanging(var message: TWMWindowPosChanging); message WM_WINDOWPOSCHANGING;

    // ������ ���Ʊ������ڲ��ؼ�
    procedure WMEraseBkgnd(var message: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure WMPaint(var message: TWMPaint); message WM_PAINT;

    // ������ ���ư�ť״̬
    procedure WMNCHitTest(var Message: TWMNCHitTest); message WM_NCHITTEST;
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

    function DoHandleMessage(var message: TMessage): Boolean;

    property Toolbar: TcpToolbar read FToolbar;
    property Handled: Boolean read FHandled write FHandled;
    property Control: TWinControl read FControl;
    property Form: TCustomForm read GetForm;
  end;


implementation

const
  SPALCE_CAPTIONAREA = 3;

{$R MySkin.RES}

type
  TacWinControl = class(TWinControl);

  Res = class
    class procedure LoadGraphic(const AName: string; AGraphic: TGraphic);
    class procedure LoadBitmap(const AName: string; AGraphic: TBitmap);
  end;

  TResArea = record
    x: Integer;
    y: Integer;
    w: Integer;
    h: Integer;
  end;

  TSkinToolbarElement = (steSplitter, stePopdown);

  SkinData = class
  private
  class var
    FData: TBitmap;

  public
    class constructor Create;
    class destructor Destroy;

    class procedure DrawButtonBackground(DC: HDC; AState: TSkinIndicator; const R: TRect); static;
    class procedure DrawButton(DC: HDC; AKind: TFormButtonKind; AState: TSkinIndicator; const R: TRect); static;
    class procedure DrawElement(DC: HDC; AItem: TSkinToolbarElement; const R: TRect);
  end;

const
  SKINCOLOR_BAKCGROUND  = $00BF7B18;  // ����ɫ
  SKINCOLOR_BTNHOT      = $00F2D5C2;  // Hot ����״̬
  SKINCOLOR_BTNPRESSED  = $00E3BDA3;  // ����״̬
  SIZE_SYSBTN: TSize    = (cx: 29; cy: 18);
  SIZE_FRAME: TRect     = (Left: 4; Top: 29; Right: 5; Bottom: 5); // ����߿�ĳߴ�
  SPACE_AREA            = 3;          // ��������֮����
  SIZE_RESICON          = 16;         // ��Դ��ͼ��Ĭ�ϳߴ�
  SIZE_HEIGHTTOOLBAR    = 16;

  RES_CAPTIONTOOLBAR: TResArea = (x: 0; y: 16; w: 9; h: 16);


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


procedure TskForm.CallDefaultProc(var message: TMessage);
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

procedure TskForm.ChangeSize;
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

function TskForm.NormalizePoint(P: TPoint): TPoint;
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

function TskForm.HitTest(P: TPoint):integer;
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

    ///
    ///  ���⹤������
    ///    ��Ҫǰ��۳�����ͼ������
    if (Result = HTNOWHERE) and (FToolbar.Visible) then
    begin
      r.Left := rCaptionRect.Left + 2 + GetSystemMetrics(SM_CXSMICON) + SPALCE_CAPTIONAREA;
      R.Top := rCaptionRect.Top + (rCaptionRect.Height - FToolbar.Border.Height) div 2;
      R.Right := R.Left + FToolbar.Border.Width;
      R.Bottom := R.Top + FToolbar.Border.Height;

      if PtInRect(r, p) then
        Result := HTCAPTIONTOOLBAR;
    end;
  end;
end;

constructor TskForm.Create(AOwner: TWinControl);
begin
  FControl := AOwner;
  FRegion := 0;
  FChangeSizeCalled := False;
  FCallDefaultProc := False;

  FWidth := FControl.Width;
  FHeight := FControl.Height;
  FIcon := nil;
  FIconHandle := 0;

  FToolbar := TcpToolbar.Create(Self);
end;

destructor TskForm.Destroy;
begin
  FToolbar.Free;

  FIconHandle := 0;
  if FIcon <> nil then      FIcon.Free;
  if FRegion <> 0 then      DeleteObject(FRegion);
  inherited;
end;

function TskForm.DoHandleMessage(var message: TMessage): Boolean;
begin
  Result := False;
  if not FCallDefaultProc then
  begin
    FHandled := False;
    WndProc(message);
    Result := Handled;
  end;
end;

function TskForm.GetFrameSize: TRect;
begin
  Result := SIZE_FRAME;
end;

function TskForm.GetCaptionRect(AMaxed: Boolean): TRect;
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

function TskForm.GetCaption: string;
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

function TskForm.GetForm: TCustomForm;
begin
  Result := TCustomForm(Control);
end;

function TskForm.GetHandle: HWND;
begin
  if FControl.HandleAllocated then
    Result := FControl.Handle
  else
    Result := 0;
end;

function TskForm.GetIcon: TIcon;
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

function TskForm.GetIconFast: TIcon;
begin
  if (FIcon = nil) or (FIconHandle = 0) then
    Result := GetIcon
  else
    Result := FIcon;
end;

procedure TskForm.InvalidateNC;
begin
  if FControl.HandleAllocated then
    SendMessage(Handle, WM_NCPAINT, 1, 0);
end;

procedure TskForm.Maximize;
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

procedure TskForm.Minimize;
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

procedure TskForm.PaintNC(DC: HDC);
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
  bClipRegion: boolean;
  hB: HBRUSH;
  rFrame: TRect;
  rButton: TRect;
  SaveIndex: integer;
  bMaxed: Boolean;
  ClipRegion: HRGN;
  CurrentIdx: Integer;
  rCaptionRect : TRect;
  sData: string;
  Flag: Cardinal;
  iLeftOff: Integer;
  iTopOff: Integer;
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

    ///
    /// ���ƴ���ͼ��
    rButton := BuildRect(rCaptionRect.Left + 2, rCaptionRect.Top, GetSystemMetrics(SM_CXSMICON), GetSystemMetrics(SM_CYSMICON));
    rButton.Top := rButton.Top + (rFrame.Top - rButton.Bottom) div 2;
    DrawIconEx(DC, rButton.Left, rButton.Top, GetIconFast.Handle, 0, 0, 0, 0, DI_NORMAL);
    rCaptionRect.Left := rButton.Right + SPALCE_CAPTIONAREA; //

    ///
    /// ���ƴ��尴ť����
    rButton.Right := rCaptionRect.Right - 1;
    rButton.Top := 0;
    if bMaxed then
      rButton.Top := rCaptionRect.Top;
    rButton.Top := rButton.Top + (rFrame.Top - rButton.Top - SIZE_SYSBTN.cy) div 2;
    rButton.Left := rButton.Right - SIZE_SYSBTN.cx;
    rButton.Bottom := rButton.Top + SIZE_SYSBTN.cy;
    SkinData.DrawButton(Dc, fbkClose, GetBtnState(fbkClose), rButton);

    OffsetRect(rButton, - SIZE_SYSBTN.cx, 0);
    if bMaxed then
      SkinData.DrawButton(Dc, fbkRestore, GetBtnState(fbkRestore), rButton)
    else
      SkinData.DrawButton(Dc, fbkMax, GetBtnState(fbkMax), rButton);

    OffsetRect(rButton, - SIZE_SYSBTN.cx, 0);
    SkinData.DrawButton(Dc, fbkMin, GetBtnState(fbkMin), rButton);
    rCaptionRect.Right := rButton.Left - SPALCE_CAPTIONAREA; // �󲿿ճ�

    ///
    /// ���ƹ�����
    if FToolbar.Visible and (rCaptionRect.Right > rCaptionRect.Left) then
    begin
      /// ��ֹ���ֻ��Ƴ��������򣬵����򲻹�ʱ��Ҫ���м��С�
      ///  �磺 ������Сʱ
      bClipRegion := rCaptionRect.Width < FToolbar.Border.Width;
      if bClipRegion then
      begin
        ClipRegion := CreateRectRgnIndirect(rCaptionRect);
        CurrentIdx := SelectClipRgn(DC, ClipRegion);
        DeleteObject(ClipRegion);
      end;

      iLeftOff := rCaptionRect.Left;
      iTopOff := rCaptionRect.Top + (rCaptionRect.Height - FToolbar.Border.Height) div 2;
      MoveWindowOrg(DC, iLeftOff, iTopOff);
      FToolbar.Paint(DC);
      MoveWindowOrg(DC, -iLeftOff, -iTopOff);

      if bClipRegion then
        SelectClipRgn(DC, CurrentIdx);

      /// �۳�����������
      rCaptionRect.Left := rCaptionRect.Left + FToolbar.Border.Width + SPALCE_CAPTIONAREA;
    end;

    ///
    /// ����Caption
    if rCaptionRect.Right > rCaptionRect.Left then
    begin
      sData :=  GetCaption;
      SetBkMode(DC, TRANSPARENT);
      SaveColor := SetTextColor(DC, $00FFFFFF);

      Flag := DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX;
      DrawTextEx(DC, PChar(sData), Length(sData), rCaptionRect, Flag, nil);
      SetTextColor(DC, SaveColor);
    end;
  finally
    RestoreDC(DC, SaveIndex);
  end;
end;

procedure TskForm.PaintBackground(DC: HDC);
var
  hB: HBRUSH;
  R: TRect;
begin
  GetClientRect(Handle, R);
  hB := CreateSolidBrush($00F0F0F0);
  FillRect(DC, R, hB);
  DeleteObject(hB);
end;

procedure TskForm.Paint(DC: HDC);
begin
  // PaintBackground(DC);
  // TODO -cMM: TskForm.Paint default body inserted
end;

procedure TskForm.WMEraseBkgnd(var message: TWMEraseBkgnd);
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

procedure TskForm.WMNCActivate(var message: TMessage);
begin
  // FFormActive := Message.WParam > 0;
  Message.Result := 1;
  InvalidateNC;
  Handled := True;
end;

procedure TskForm.WMNCCalcSize(var message: TWMNCCalcSize);
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

procedure TskForm.WMNCHitTest(var Message: TWMNCHitTest);
var
  P: TPoint;
  iHit: integer;
begin
  // ��Ҫ��λ��ת����ʵ�ʴ���λ��
  P := NormalizePoint(Point(Message.XPos, Message.YPos));

  // ��ȡ λ��
  iHit := HitTest(p);
  if FHotHit > HTNOWHERE then
  begin
    Message.Result := iHit;
    Handled := True;
  end;

  if iHit <> FHotHit then
  begin
    FHotHit := iHit;
    InvalidateNC;
  end;

end;

procedure TskForm.WMWindowPosChanging(var message: TWMWindowPosChanging);
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

procedure TskForm.WMNCLButtonDown(var message: TWMNCHitMessage);
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

procedure TskForm.WMNCLButtonUp(var Message: TWMNCHitMessage);
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

procedure TskForm.WMNCMouseMove(var Message: TWMNCMouseMove);
begin
  if (FPressedHit <> HTNOWHERE) and (FPressedHit <> Message.HitTest) then
    FPressedHit := HTNOWHERE;
end;

procedure TskForm.WMSetText(var Message: TMessage);
begin
  CallDefaultProc(Message);
  InvalidateNC;
  Handled := true;
end;

procedure TskForm.WMNCPaint(var message: TWMNCPaint);
var
  DC: HDC;
begin
  DC := GetWindowDC(Control.Handle);
  PaintNC(DC);
  ReleaseDC(Handle, DC);
  Handled := True;
end;

procedure TskForm.WMNCUAHDrawCaption(var message: TMessage);
begin
  /// �����Ϣ����winxp�²��������ڲ�Bug����ֱ�Ӷ�������Ϣ
  Handled := True;
end;

procedure TskForm.WMPaint(var message: TWMPaint);
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

procedure TskForm.WndProc(var message: TMessage);
begin
  FHandled := False;
  Dispatch(message);
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

class constructor SkinData.Create;
begin
  // ������Դ
  FData := TBitmap.Create;
  Res.LoadBitmap('MySkin', FData);
end;

class destructor SkinData.Destroy;
begin
  FData.Free;
end;

class procedure SkinData.DrawButton(DC: HDC; AKind: TFormButtonKind; AState:
    TSkinIndicator; const R: TRect);
var
  rSrcOff: TPoint;
  x, y: integer;
begin
  /// ���Ʊ���
  DrawButtonBackground(DC, AState, R);

  /// ����ͼ��
  rSrcOff := Point(SIZE_RESICON * ord(AKind), 0);
  x := R.Left + (R.Right - R.Left - SIZE_RESICON) div 2;
  y := R.Top + (R.Bottom - R.Top - SIZE_RESICON) div 2;
  DrawTransparentBitmap(FData, rSrcOff.X, rSrcOff.Y, DC, x, y, SIZE_RESICON, SIZE_RESICON);
end;


class procedure SkinData.DrawButtonBackground(DC: HDC; AState: TSkinIndicator; const R: TRect);
var
  hB: HBRUSH;
  iColor: Cardinal;
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
end;

class procedure SkinData.DrawElement(DC: HDC; AItem: TSkinToolbarElement; const R: TRect);
var
  rSrc: TResArea;
  x, y: integer;
begin
  rSrc := RES_CAPTIONTOOLBAR;
  rSrc.x :=  rSrc.x + rSrc.w * (ord(AItem) - ord(Low(TSkinToolbarElement)));

  /// ����ͼ��
  x := R.Left + (R.Right - R.Left - rSrc.w) div 2;
  y := R.Top + (R.Bottom - R.Top - rSrc.h) div 2;
  DrawTransparentBitmap(FData, rSrc.x, rSrc.y, DC, x, y, rSrc.w, rSrc.h);
end;

{ TcpToolbar }

procedure TcpToolbar.Add(Action: TBasicAction; AImageIndex: Integer);
begin
  if FCount >= Length(FItems) then
    SetLength(FItems, FCount + 5);

  ZeroMemory(@FItems[FCount], SizeOf(TcpToolButton));
  FItems[FCount].Action := Action;
  FItems[FCount].ImageIndex := AImageIndex;

  inc(FCount);

  Update;
end;

function TcpToolbar.CalcSize: TRect;
const
  SIZE_SPLITER = 10;
  SIZE_BUTTON = 16;
  SIZE_POPMENU = 10;
var
  w, h: Integer;
begin
  ///
  ///  ռ�ÿ��
  ///     ������ǱȽϸ��ӵİ�ť��ʽ����ʾ����ȹ��ܣ���ô��Ҫ����ÿ����ťʵ��ռ�ÿ�Ȳ��ܻ�á�
  w := SIZE_SPLITER * 2 + SIZE_POPMENU + SIZE_BUTTON * FCount;
  h := SIZE_BUTTON;
  Result := Rect(0, 0, w, h);
end;

procedure TcpToolbar.Delete(Index: Integer);
begin
  if (Index >= 0) and (Index < FCount) then
  begin
    if Index < (FCount - 1) then
      Move(FItems[Index+1], FItems[Index], sizeof(TcpToolButton) * (FCount - Index - 1));
    dec(FCount);

    Update;
  end;
end;

function TcpToolbar.IndexOf(Action: TBasicAction): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to FCount - 1 do
    if FItems[i].Action = Action then
    begin
      Result := i;
      Break;
    end;
end;

procedure TcpToolbar.Paint(DC: HDC);
var
  r: TRect;
begin
  //SkinData.DrawButtonBackground(DC, siHover, Border);

  /// �ָ���
  r := Border;
  r.Right := r.Left + RES_CAPTIONTOOLBAR.w;
  SkinData.DrawElement(DC, steSplitter, r);

  OffsetRect(r, r.Right - r.Left, 0);
  r.Right := r.Left + RES_CAPTIONTOOLBAR.w;
  SkinData.DrawElement(DC, stePopdown, r);

  OffsetRect(r, r.Right - r.Left, 0);
  r.Right := r.Left + RES_CAPTIONTOOLBAR.w;
  SkinData.DrawElement(DC, steSplitter, r);
end;

constructor TFormCaptionPlugin.Create(AOwner: TskForm);
begin
  FOwner := AOwner;
  FVisible := True;
  FBorder := CalcSize;
end;

procedure TFormCaptionPlugin.Invalidate;
begin
  FOwner.InvalidateNC;
end;

procedure TFormCaptionPlugin.Update;
begin
  FBorder := CalcSize;
  Invalidate;
end;

end.

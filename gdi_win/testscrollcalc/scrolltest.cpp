//
// �Զ������������
// 
// Created by Ģ���� moguf.com
//
#include <windows.h>
#include <Winuser.h> // setScrollPos
#include <Windowsx.h> // GET_Y_LPARAM
#include "strsafe.h" // how to scroll text ��MyTextWindowProc��


LRESULT CALLBACK WndProc(HWND, UINT, WPARAM, LPARAM);           // ��������Ϣ����
LRESULT CALLBACK scrollWndProc(HWND, UINT, WPARAM, LPARAM);     // ��������Ϣ����

// microsoft demo
LRESULT CALLBACK MyTextWindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);


int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance,
                   PSTR szCmdLine, int iCmdShow)
{
    static TCHAR szAppName[] = TEXT("scrollcalctest");
    HWND         hwnd;
    MSG          msg;
    WNDCLASS     wndclass;

    wndclass.style         = CS_HREDRAW | CS_VREDRAW;
    wndclass.lpfnWndProc   = WndProc;// MyTextWindowProc; // MyBitmapWindowProc;
    wndclass.cbClsExtra    = 0;
    wndclass.cbWndExtra    = 0;
    wndclass.hInstance     = hInstance;
    wndclass.hIcon         = LoadIcon(NULL, IDI_APPLICATION);
    wndclass.hCursor       = LoadCursor(NULL, IDC_ARROW);
    wndclass.hbrBackground = (HBRUSH)GetStockObject(WHITE_BRUSH);
    wndclass.lpszMenuName  = NULL;
    wndclass.lpszClassName = szAppName;

    if (!RegisterClass(&wndclass))
        return 0;

    // scroll class
    wndclass.style = 0;
    wndclass.lpfnWndProc   = scrollWndProc;
    wndclass.lpszClassName = TEXT("myscroll");
    wndclass.hbrBackground = 0;
    if (!RegisterClass(&wndclass))
        return 0;

    hwnd = CreateWindow(szAppName, TEXT("���Թ�����"),
                        WS_OVERLAPPEDWINDOW | WS_VSCROLL,
                        600, 400, 350, 250,
                        NULL, NULL, hInstance, NULL);

    ShowWindow(hwnd, iCmdShow);
    UpdateWindow(hwnd);

    while (GetMessage(&msg, NULL, 0, 0))
    {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }
    return (int)msg.wParam;
}

LRESULT CALLBACK WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static HWND hScroll;
    static int  rowCount, rowHeight, xClient, yClient;
    HDC         hdc;
    int         i, y, vertPos, printBeg, printEnd;
    PAINTSTRUCT ps;
    SCROLLINFO  si;
    TCHAR       szBuffer[100];
    TEXTMETRIC  tm;
    RECT        r;

    switch (message)
    {
    case WM_CREATE:

        // ���Ե�ǰ�������������ڲ��Թ�����
        rowCount = 100;

        // ��ȡһ�и߶�
        hdc = GetDC(hwnd);
        GetTextMetrics(hdc, &tm);
        rowHeight = tm.tmHeight + tm.tmExternalLeading;
        ReleaseDC(hwnd, hdc);

        hScroll = CreateWindow(TEXT("myscroll"), TEXT("myscroll"), WS_CHILD | WS_VISIBLE | BS_OWNERDRAW,
                                  300, 10, 16, 300,
                                  hwnd, 0, ((LPCREATESTRUCT)lParam)->hInstance, NULL);

       
        return 0;

    case WM_SIZE:
        xClient = LOWORD(lParam);
        yClient = HIWORD(lParam);


        // ���ù�����

        si.cbSize = sizeof(si);
        si.fMask  = SIF_RANGE | SIF_PAGE;
        si.nMin   = 0;
        //
        // ֻҪ����1�о��ܹ����������Ҫ���һҳ��������
        si.nMax   = rowCount - 1 + yClient / rowHeight - 1;
        si.nPage  = yClient / rowHeight;
        SetScrollInfo(hwnd, SB_VERT, &si, TRUE);

        // ����������λ��
        MoveWindow(hScroll, xClient - 100, 10 , 16, yClient - 20, true);
        SendMessage(hScroll, SBM_SETSCROLLINFO, TRUE, (LPARAM)(&si));

        return 0;

    case WM_VSCROLL:

        // ��ȡ��������״̬
        si.cbSize = sizeof(si);
        si.fMask  = SIF_ALL;
        GetScrollInfo(hwnd, SB_VERT, &si);
        
        // ����ԭ����λ�ã����ڼ��������ǰ������
        vertPos = si.nPos;

        // lParam ����Ϊ�������ؼ�����׼������û���������
        if (lParam) 
            SendMessage(hScroll, SBM_GETSCROLLINFO, NULL, (LPARAM)(&si));

        // ���ù�����
        switch (LOWORD(wParam))
        {
        case SB_TOP:        si.nPos = si.nMin;      break;
        case SB_BOTTOM:     si.nPos = si.nMax;      break;
        case SB_LINEUP:     si.nPos -= 1;           break;
        case SB_LINEDOWN:   si.nPos += 1;           break;
        case SB_PAGEUP:     si.nPos -= si.nPage;    break;
        case SB_PAGEDOWN:   si.nPos += si.nPage;    break;
        case SB_THUMBTRACK: si.nPos = si.nTrackPos; break;
        default:    break;
        }

        // ����ϵͳ������״̬
        si.fMask = SIF_POS;
        SetScrollInfo(hwnd, SB_VERT, &si, TRUE);
        GetScrollInfo(hwnd, SB_VERT, &si);

        // �������滭��
        if (si.nPos != vertPos) {
            GetClientRect(hwnd, &r);
            r.right -= 150; // ��Ҫˢ��������λ�ã��������

            hdc = GetDC(hwnd);
            ScrollDC(hdc, 0, rowHeight * (vertPos - si.nPos), &r, NULL, NULL, NULL);
            ReleaseDC(hwnd, hdc);

            if (rowHeight * (vertPos - si.nPos) < 0 ) r.top = r.bottom + rowHeight * (vertPos - si.nPos);
            else r.bottom = r.top + rowHeight * (vertPos - si.nPos);
            InvalidateRect(hwnd, &r, false);
        }

        // ֪ͨ�Զ������������
        SendMessage(hScroll, SBM_SETSCROLLINFO, TRUE, (LPARAM)(&si));

        return 0;

    case WM_MOUSEWHEEL:
        // ��Ϣ���͵��������ؼ�
        PostMessage(hScroll, WM_MOUSEWHEEL, wParam, lParam);
        return 0;

    case WM_PAINT:
        hdc = BeginPaint(hwnd, &ps);

        // ��ȡ��������״̬
        si.cbSize = sizeof(si);
        si.fMask  = SIF_ALL;
        GetScrollInfo(hwnd, SB_VERT, &si);
        vertPos = si.nPos;

        // �ػ��޸ĵ�λ�ã������ػ�����
        printBeg = max(0, vertPos + ps.rcPaint.top / rowHeight);
        printEnd = min(rowCount - 1, vertPos + ps.rcPaint.bottom / rowHeight);
        // �����ǰ�к�
        for (i = printBeg; i <= printEnd; i++)
        {
            y = rowHeight * (i - vertPos);
            TextOut(hdc, 22 , y, szBuffer, wsprintf(szBuffer, TEXT("%5d   "), i+1));
        }

        // ���հ�����
        y = rowHeight * (printEnd + 1 - vertPos);
        if (ps.rcPaint.bottom - y > 0) {
            r = ps.rcPaint;
            r.top = y;
            ExtTextOut(hdc, 0, 0, ETO_OPAQUE, &r, 0, 0, 0);
        }
        EndPaint(hwnd, &ps);

        return 0;

    case WM_DESTROY:
        PostQuitMessage(0);
        return 0;
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}

static void mlCGFillColor(HDC hdc, RECT *r, unsigned int color)
{
    // ʵ��ʹ��ExtTextOutҪ��FillRect�����ɫЧ���ã��ܼ��ٻ�������˸���⡣
    SetBkColor(hdc, color);
    ExtTextOut(hdc, 0, 0, ETO_OPAQUE, r, 0, 0, 0);
}

// ���������λ��
static int calcVertThumPos(int postion, SCROLLINFO *si, int s)
{
    float thumsize;     // ����Ĵ�С
    float pxSize;       // ÿ���ؿɻ�����
    int   scrollCnt;    // �ɻ�������

    // ����ߴ� =  �������߶� / ��Ч��Χ * ÿҳ����
    //            ��С 20
    thumsize = max((float)((s) / (si->nMax - si->nMin) * si->nPage), 20.0f);
    if (postion <= (int)(thumsize / 2))
        return 0;
    if (postion >= s - (thumsize / 2))
        return (si->nMax - si->nMin + 1) - si->nPage;

    // ���㷽����
    //  ÿ���ػ����� = ��Ч�߶� / �ɻ�������
    //  ��Ч�߶�     = �ܸ߶� - ����ߴ�
    //  �ɻ�������   = ���� - ÿҳ����
    scrollCnt = (si->nMax - si->nMin + 1) - si->nPage;
    pxSize = (float)(s - thumsize) / (float)scrollCnt;

    //
    // ���㷽����
    //   λ�� = �����λ�� - �뻬��ߴ磩 / ÿ���ػ�����
    return (int)((postion - thumsize / 2.0) / pxSize);
}

LRESULT CALLBACK scrollWndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    HDC hdc;
    PAINTSTRUCT ps;
    SCROLLINFO *psrcsi;
    RECT r;

    TCHAR       szBuffer[100];

    float s;                // ����ĳߴ�
    int v;                  // �������Topλ��
    static SCROLLINFO  si;  // ���ڱ����������Ϣ
    static int dragState;   // ��ק״̬
    static int height;      // ��������߶�

    int accumDelta;

    //
    // ������������Ϣ
    //  SBM_SETSCROLLINFO SBM_GETSCROLLINFO ��Ϣ����
    //  wParam --- �Ƿ�Ҫˢ�� (SBM_GETSCROLLINFO ����)
    //  lParam --- *SCROLLINFO
    switch (message) {
    case SBM_SETSCROLLINFO:
        if (!lParam)
            return 0;

        // ���ù�������Ϣ
        psrcsi = (SCROLLINFO *)lParam;
        if (psrcsi->fMask & SIF_RANGE) {    // ������������
            si.nMax = psrcsi->nMax;
            si.nMin = psrcsi->nMin;
        }
        if (psrcsi->fMask & SIF_PAGE)       // ÿҳ����ʾ������
            si.nPage = psrcsi->nPage;
        if (psrcsi->fMask & SIF_POS)        // ����ʾλ��
            si.nPos = psrcsi->nPos;

        wsprintf(szBuffer, TEXT("yPos:%3d "), si.nPos);
        SetWindowText(GetParent(hwnd), szBuffer);

        // wParam = true��ˢ�¹�������
        if (wParam) 
            InvalidateRect(hwnd, NULL, false);
        return 0;

    case SBM_GETSCROLLINFO:
        //����򵥴���Ӧ�ú�SBM_SETSCROLLINFOһ���жϻ�ȡ����Ϣ��
        if (lParam)
            *(SCROLLINFO *)lParam = si;     
        return 0;

    case WM_SIZE:
        height = HIWORD(lParam);
        break;

    case WM_LBUTTONDOWN:
        si.nTrackPos = calcVertThumPos(GET_Y_LPARAM(lParam), &si, height);
        if (si.nPos != si.nTrackPos) 
            PostMessage(GetParent(hwnd), WM_VSCROLL, SB_THUMBTRACK, (LPARAM)hwnd);
        dragState = 1; // ׼���϶�������
        InvalidateRect(hwnd, NULL, false);
        return 0;
    
    case WM_MOUSEMOVE:
        if (dragState == 1) {
            // ����ק׼��������������
            SetCapture(hwnd);
            dragState = 2;
            
        }
        else if (dragState == 2) {
            if (!(wParam & MK_LBUTTON)) {
                dragState = 0;              // ��ֹ�м��жϣ����³�����Ч��ק
                if (GetCapture() == hwnd)
                    ReleaseCapture();
            }
            else {
                // ������״̬���϶���������λ��
                si.nTrackPos = calcVertThumPos(GET_Y_LPARAM(lParam), &si, height);
                if (si.nTrackPos != si.nPos)
                    PostMessage(GetParent(hwnd), WM_VSCROLL, SB_THUMBTRACK, (LPARAM)hwnd);
            }
        }
        return 0;

    case WM_LBUTTONUP:
        if (dragState == 2) 
            ReleaseCapture();   // �ͷ��������

        if (dragState) {
            dragState = 0;          // ���״̬
            InvalidateRect(hwnd, NULL, false);
        }
        return 0;

    case WM_MOUSEWHEEL:
        // ������֧��
        accumDelta = GET_WHEEL_DELTA_WPARAM(wParam) / WHEEL_DELTA;  // ��������120һ����λ
        si.nTrackPos = si.nPos - accumDelta * 3;   // ÿ��һ��3��
        if (si.nTrackPos < 0)
            si.nTrackPos = 0;
        else if (si.nTrackPos > (int)((si.nMax - si.nMin + 1) - si.nPage))
            si.nTrackPos = (si.nMax - si.nMin + 1) - si.nPage;

        if (si.nPos != si.nTrackPos)
            PostMessage(GetParent(hwnd), WM_VSCROLL, SB_THUMBTRACK, (LPARAM)hwnd);
            
        return 0;


    case WM_PAINT:
        hdc = BeginPaint(hwnd, &ps);

        // ���Ʊ���ɫ
        GetClientRect(hwnd, &r);
        mlCGFillColor(hdc, &r, 0xcccccc);

        // ���㻬���С����Сʱ������
        if (r.bottom - r.top > 30 && si.nMax && (si.nMax - si.nMin) >= (int)si.nPage) {

            // �������
            //   ��С = �������߶� / ��Ч��Χ * ÿҳ����
            //   ��С20, ���ݱȽ϶࣬����������궨λ���������϶����Ѷȡ�
            s = max((float)((r.bottom - r.top) / (si.nMax - si.nMin) * si.nPage), 20.0f);

            // ʵ�ʻ���λ��
            //  = ���������߶� - ����ߴ磩 / ����Ч��Χ - ÿҳ���� + 1�� * ��ǰ��λ��
            // ʵ�ʹ�����λ�û��ʵ����һҳ��������
            //
            v = 0;
            if (si.nPos > 0) 
                v = (int)((r.bottom - r.top - s) / (float)(si.nMax - si.nMin + 1 - si.nPage)  * si.nPos);
            // ���ھ������⣬���ܻ���λ�ûᳬ�硣�����ȡ���ֵ
            if (v && v + (int)s > r.bottom) 
                v = r.bottom - (int)s;

            // ���ƻ���
            r.left++;
            r.right--;
            r.top = v ;
            r.bottom = r.top + (int)s;
            
            // ��קʱ������ɫ��һ��
            mlCGFillColor(hdc, &r, dragState ? 0x999999 : 0x666666e);
            InflateRect(&r, -1, -1);
            mlCGFillColor(hdc, &r, dragState ? 0x666666e : 0x999999);
        }

        EndPaint(hwnd, &ps);

        return 0;
    }
    return DefWindowProc(hwnd, message, wParam, lParam);
}



LRESULT CALLBACK MyTextWindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
    //
    // How to Scroll Text
    // https://msdn.microsoft.com/en-us/library/windows/desktop/hh298421(v=vs.85).aspx
    // 

    HDC hdc;
    PAINTSTRUCT ps;
    TEXTMETRIC tm;
    SCROLLINFO si;

    // These variables are required to display text. 
    static int xClient;     // width of client area 
    static int yClient;     // height of client area 
    static int xClientMax;  // maximum width of client area 

    static int xChar;       // horizontal scrolling unit 
    static int yChar;       // vertical scrolling unit 
    static int xUpper;      // average width of uppercase letters 

    static int xPos;        // current horizontal scrolling position 
    static int yPos;        // current vertical scrolling position 

    int i;                  // loop counter 
    int x, y;               // horizontal and vertical coordinates

    int FirstLine;          // first line in the invalidated area 
    int LastLine;           // last line in the invalidated area 
    HRESULT hr;
    size_t abcLength;        // length of an abc[] item 

                             // Create an array of lines to display. 
#define LINES 28 
    static TCHAR *abc[] ={
        TEXT("anteater"),  TEXT("bear"),      TEXT("cougar"),
        TEXT("dingo"),     TEXT("elephant"),  TEXT("falcon"),
        TEXT("gazelle"),   TEXT("hyena"),     TEXT("iguana"),
        TEXT("jackal"),    TEXT("kangaroo"),  TEXT("llama"),
        TEXT("moose"),     TEXT("newt"),      TEXT("octopus"),
        TEXT("penguin"),   TEXT("quail"),     TEXT("rat"),
        TEXT("squid"),     TEXT("tortoise"),  TEXT("urus"),
        TEXT("vole"),      TEXT("walrus"),    TEXT("xylophone"),
        TEXT("yak"),       TEXT("zebra"),
        TEXT("This line contains words, but no character. Go figure."),
        TEXT("")
    };

    switch (uMsg)
    {
    case WM_CREATE:
        // Get the handle to the client area's device context. 
        hdc = GetDC(hwnd);

        // Extract font dimensions from the text metrics. 
        GetTextMetrics(hdc, &tm);
        xChar = tm.tmAveCharWidth;
        xUpper = (tm.tmPitchAndFamily & 1 ? 3 : 2) * xChar / 2;
        yChar = tm.tmHeight + tm.tmExternalLeading;

        // Free the device context. 
        ReleaseDC(hwnd, hdc);

        // Set an arbitrary maximum width for client area. 
        // (xClientMax is the sum of the widths of 48 average 
        // lowercase letters and 12 uppercase letters.) 
        xClientMax = 48 * xChar + 12 * xUpper;

        return 0;

    case WM_SIZE:

        // Retrieve the dimensions of the client area. 
        yClient = HIWORD(lParam);
        xClient = LOWORD(lParam);

        // Set the vertical scrolling range and page size
        si.cbSize = sizeof(si);
        si.fMask  = SIF_RANGE | SIF_PAGE;
        si.nMin   = 0;
        si.nMax   = LINES - 1;
        si.nPage  = yClient / yChar;
        SetScrollInfo(hwnd, SB_VERT, &si, TRUE);

        // Set the horizontal scrolling range and page size. 
        si.cbSize = sizeof(si);
        si.fMask  = SIF_RANGE | SIF_PAGE;
        si.nMin   = 0;
        si.nMax   = 2 + xClientMax / xChar;
        si.nPage  = xClient / xChar;
        SetScrollInfo(hwnd, SB_HORZ, &si, TRUE);

        return 0;
    case WM_HSCROLL:
        // Get all the vertial scroll bar information.
        si.cbSize = sizeof(si);
        si.fMask  = SIF_ALL;

        // Save the position for comparison later on.
        GetScrollInfo(hwnd, SB_HORZ, &si);
        xPos = si.nPos;
        switch (LOWORD(wParam))
        {
            // User clicked the left arrow.
        case SB_LINELEFT:
            si.nPos -= 1;
            break;

            // User clicked the right arrow.
        case SB_LINERIGHT:
            si.nPos += 1;
            break;

            // User clicked the scroll bar shaft left of the scroll box.
        case SB_PAGELEFT:
            si.nPos -= si.nPage;
            break;

            // User clicked the scroll bar shaft right of the scroll box.
        case SB_PAGERIGHT:
            si.nPos += si.nPage;
            break;

            // User dragged the scroll box.
        case SB_THUMBTRACK:
            si.nPos = si.nTrackPos;
            break;

        default:
            break;
        }

        // Set the position and then retrieve it.  Due to adjustments
        // by Windows it may not be the same as the value set.
        si.fMask = SIF_POS;
        SetScrollInfo(hwnd, SB_HORZ, &si, TRUE);
        GetScrollInfo(hwnd, SB_HORZ, &si);

        // If the position has changed, scroll the window.
        if (si.nPos != xPos)
        {
            ScrollWindow(hwnd, xChar * (xPos - si.nPos), 0, NULL, NULL);
        }

        return 0;

    case WM_VSCROLL:
        // Get all the vertial scroll bar information.
        si.cbSize = sizeof(si);
        si.fMask  = SIF_ALL;
        GetScrollInfo(hwnd, SB_VERT, &si);

        // Save the position for comparison later on.
        yPos = si.nPos;
        switch (LOWORD(wParam))
        {

            // User clicked the HOME keyboard key.
        case SB_TOP:
            si.nPos = si.nMin;
            break;

            // User clicked the END keyboard key.
        case SB_BOTTOM:
            si.nPos = si.nMax;
            break;

            // User clicked the top arrow.
        case SB_LINEUP:
            si.nPos -= 1;
            break;

            // User clicked the bottom arrow.
        case SB_LINEDOWN:
            si.nPos += 1;
            break;

            // User clicked the scroll bar shaft above the scroll box.
        case SB_PAGEUP:
            si.nPos -= si.nPage;
            break;

            // User clicked the scroll bar shaft below the scroll box.
        case SB_PAGEDOWN:
            si.nPos += si.nPage;
            break;

            // User dragged the scroll box.
        case SB_THUMBTRACK:
            si.nPos = si.nTrackPos;
            break;

        default:
            break;
        }

        // Set the position and then retrieve it.  Due to adjustments
        // by Windows it may not be the same as the value set.
        si.fMask = SIF_POS;
        SetScrollInfo(hwnd, SB_VERT, &si, TRUE);
        GetScrollInfo(hwnd, SB_VERT, &si);

        // If the position has changed, scroll window and update it.
        if (si.nPos != yPos)
        {
            ScrollWindow(hwnd, 0, yChar * (yPos - si.nPos), NULL, NULL);
            UpdateWindow(hwnd);
        }

        return 0;

    case WM_PAINT:
        // Prepare the window for painting.
        hdc = BeginPaint(hwnd, &ps);

        // Get vertical scroll bar position.
        si.cbSize = sizeof(si);
        si.fMask  = SIF_POS;
        GetScrollInfo(hwnd, SB_VERT, &si);
        yPos = si.nPos;

        // Get horizontal scroll bar position.
        GetScrollInfo(hwnd, SB_HORZ, &si);
        xPos = si.nPos;

        // Find painting limits.
        FirstLine = max(0, yPos + ps.rcPaint.top / yChar);
        LastLine = min(LINES - 1, yPos + ps.rcPaint.bottom / yChar);

        for (i = FirstLine; i <= LastLine; i++)
        {
            x = xChar * (1 - xPos);
            y = yChar * (i - yPos);

            // Note that "55" in the following depends on the 
            // maximum size of an abc[] item. Also, you must include
            // strsafe.h to use the StringCchLength function.
            hr = StringCchLength(abc[i], 55, &abcLength);
            if ((FAILED(hr)) | (abcLength == NULL))
            {
                //
                // TODO: write error handler
                //
            }

            // Write a line of text to the client area.
            TextOut(hdc, x, y, abc[i], (int)abcLength);
        }

        // Indicate that painting is finished.
        EndPaint(hwnd, &ps);
        return 0;

    case WM_DESTROY:
        PostQuitMessage(0);
        return 0;
    }

    return DefWindowProc(hwnd, uMsg, wParam, lParam);
}
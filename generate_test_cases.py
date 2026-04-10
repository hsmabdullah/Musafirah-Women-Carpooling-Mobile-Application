from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import cm
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    HRFlowable, PageBreak, KeepTogether
)
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_RIGHT
from reportlab.platypus import BaseDocTemplate, PageTemplate, Frame
from reportlab.pdfgen import canvas
from datetime import date

OUTPUT = "Musafirah_Test_Cases.pdf"
PAGE_W, PAGE_H = A4
MARGIN = 1.8 * cm

PRIMARY   = colors.HexColor("#FC153B")
DARK      = colors.HexColor("#1A1A2E")
LIGHT_RED = colors.HexColor("#FFF0F3")
GREY_BG   = colors.HexColor("#F7F7F7")
PASS_CLR  = colors.HexColor("#27AE60")
FAIL_CLR  = colors.HexColor("#E74C3C")
HEAD_TEXT = colors.white
BORDER    = colors.HexColor("#E0E0E0")
LIGHT_HDR = colors.HexColor("#FDEAEE")

styles = getSampleStyleSheet()

def s(name, **kw):
    base = styles[name]
    return ParagraphStyle(name + str(kw), parent=base, **kw)

title_style   = s("Title",   fontSize=26, textColor=DARK,    spaceAfter=4,  fontName="Helvetica-Bold", alignment=TA_CENTER)
sub_style     = s("Normal",  fontSize=11, textColor=PRIMARY,  spaceAfter=2,  fontName="Helvetica",      alignment=TA_CENTER)
meta_style    = s("Normal",  fontSize=9,  textColor=colors.grey, spaceAfter=2, fontName="Helvetica",   alignment=TA_CENTER)
h1_style      = s("Heading1",fontSize=14, textColor=HEAD_TEXT, fontName="Helvetica-Bold", spaceBefore=0, spaceAfter=0)
h2_style      = s("Heading2",fontSize=11, textColor=DARK,      fontName="Helvetica-Bold", spaceBefore=8, spaceAfter=4)
body_style    = s("Normal",  fontSize=9,  textColor=DARK,      fontName="Helvetica",      leading=13)
small_style   = s("Normal",  fontSize=8,  textColor=colors.HexColor("#555555"), fontName="Helvetica", leading=11)
tc_id_style   = s("Normal",  fontSize=8,  textColor=PRIMARY,   fontName="Helvetica-Bold")
bold_style    = s("Normal",  fontSize=9,  textColor=DARK,      fontName="Helvetica-Bold")


# ── Page numbering ────────────────────────────────────────────────────────────

class NumberedCanvas(canvas.Canvas):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_number(num_pages)
            super().showPage()
        super().save()

    def draw_page_number(self, page_count):
        pg = self._pageNumber
        self.setFont("Helvetica", 8)
        self.setFillColor(colors.grey)
        self.drawRightString(PAGE_W - MARGIN, 0.8 * cm,
                             f"Page {pg} of {page_count}")
        self.drawString(MARGIN, 0.8 * cm,
                        "Musafirah – Women Carpooling App  |  Test Case Document")
        self.setStrokeColor(BORDER)
        self.setLineWidth(0.5)
        self.line(MARGIN, 1.1 * cm, PAGE_W - MARGIN, 1.1 * cm)


# ── Helpers ───────────────────────────────────────────────────────────────────

def section_header(title):
    tbl = Table([[Paragraph(title, h1_style)]], colWidths=[PAGE_W - 2 * MARGIN])
    tbl.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), PRIMARY),
        ("TOPPADDING",    (0, 0), (-1, -1), 8),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
        ("LEFTPADDING",   (0, 0), (-1, -1), 12),
        ("RIGHTPADDING",  (0, 0), (-1, -1), 12),
        ("ROUNDEDCORNERS", [4]),
    ]))
    return tbl


def tc_table(rows):
    """
    rows = list of dicts with keys:
      tc_id, description, preconditions, steps, expected, priority, status
    """
    col_w = [1.6*cm, 3.5*cm, 3.2*cm, 5.0*cm, 4.5*cm, 1.4*cm, 1.4*cm]

    header = [
        Paragraph("TC ID",         bold_style),
        Paragraph("Description",   bold_style),
        Paragraph("Preconditions", bold_style),
        Paragraph("Test Steps",    bold_style),
        Paragraph("Expected Result",bold_style),
        Paragraph("Priority",      bold_style),
        Paragraph("Status",        bold_style),
    ]
    data = [header]

    for r in rows:
        pri_color = {"High": colors.HexColor("#E74C3C"),
                     "Medium": colors.HexColor("#F39C12"),
                     "Low": colors.HexColor("#27AE60")}.get(r["priority"], DARK)

        data.append([
            Paragraph(r["tc_id"],        tc_id_style),
            Paragraph(r["description"],  small_style),
            Paragraph(r["preconditions"],small_style),
            Paragraph(r["steps"],        small_style),
            Paragraph(r["expected"],     small_style),
            Paragraph(f'<font color="{pri_color.hexval()}">{r["priority"]}</font>', small_style),
            Paragraph(r["status"],       small_style),
        ])

    tbl = Table(data, colWidths=col_w, repeatRows=1)
    style_cmds = [
        ("BACKGROUND",    (0, 0), (-1, 0),  LIGHT_HDR),
        ("TEXTCOLOR",     (0, 0), (-1, 0),  PRIMARY),
        ("FONTNAME",      (0, 0), (-1, 0),  "Helvetica-Bold"),
        ("FONTSIZE",      (0, 0), (-1, -1), 8),
        ("ROWBACKGROUNDS",(0, 1), (-1, -1), [colors.white, GREY_BG]),
        ("GRID",          (0, 0), (-1, -1), 0.4, BORDER),
        ("TOPPADDING",    (0, 0), (-1, -1), 4),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
        ("LEFTPADDING",   (0, 0), (-1, -1), 5),
        ("RIGHTPADDING",  (0, 0), (-1, -1), 5),
        ("VALIGN",        (0, 0), (-1, -1), "TOP"),
    ]
    tbl.setStyle(TableStyle(style_cmds))
    return tbl


def build_pdf(story):
    doc = SimpleDocTemplate(
        OUTPUT,
        pagesize=A4,
        leftMargin=MARGIN, rightMargin=MARGIN,
        topMargin=MARGIN,  bottomMargin=1.8*cm,
        title="Musafirah Test Cases",
        author="Musafirah QA Team",
    )
    doc.build(story, canvasmaker=NumberedCanvas)
    print(f"PDF generated: {OUTPUT}")


# ── Cover page ────────────────────────────────────────────────────────────────

def cover():
    elems = []
    elems.append(Spacer(1, 3*cm))

    # Logo placeholder bar
    bar = Table([[ Paragraph("MUSAFIRAH", s("Normal", fontSize=36,
                   textColor=colors.white, fontName="Helvetica-Bold",
                   alignment=TA_CENTER)) ]],
                colWidths=[PAGE_W - 2*MARGIN])
    bar.setStyle(TableStyle([
        ("BACKGROUND",    (0,0),(-1,-1), PRIMARY),
        ("TOPPADDING",    (0,0),(-1,-1), 18),
        ("BOTTOMPADDING", (0,0),(-1,-1), 18),
        ("ROUNDEDCORNERS",[6]),
    ]))
    elems.append(bar)
    elems.append(Spacer(1, 0.5*cm))
    elems.append(Paragraph("Women Carpooling Mobile Application", sub_style))
    elems.append(Spacer(1, 1.2*cm))
    elems.append(HRFlowable(width="100%", thickness=1, color=PRIMARY))
    elems.append(Spacer(1, 0.6*cm))
    elems.append(Paragraph("TEST CASE DOCUMENT", s("Normal", fontSize=20,
                 textColor=DARK, fontName="Helvetica-Bold", alignment=TA_CENTER)))
    elems.append(Spacer(1, 0.4*cm))
    elems.append(Paragraph("Comprehensive Functional &amp; UI Test Cases", sub_style))
    elems.append(Spacer(1, 1.5*cm))

    meta_rows = [
        ["Document Version", "1.0"],
        ["Prepared Date",    str(date.today().strftime("%B %d, %Y"))],
        ["Application",      "Musafirah – Women Carpooling App"],
        ["Platform",         "Android / iOS (Flutter)"],
        ["Test Type",        "Functional, UI, Integration, Edge Cases"],
        ["Prepared By",      "Musafirah QA Team"],
    ]
    meta_tbl = Table(
        [[Paragraph(k, bold_style), Paragraph(v, body_style)] for k, v in meta_rows],
        colWidths=[5*cm, 11.5*cm]
    )
    meta_tbl.setStyle(TableStyle([
        ("BACKGROUND",    (0,0), (0,-1), LIGHT_RED),
        ("BACKGROUND",    (1,0), (1,-1), colors.white),
        ("GRID",          (0,0), (-1,-1), 0.4, BORDER),
        ("TOPPADDING",    (0,0), (-1,-1), 6),
        ("BOTTOMPADDING", (0,0), (-1,-1), 6),
        ("LEFTPADDING",   (0,0), (-1,-1), 10),
        ("ROUNDEDCORNERS",[4]),
    ]))
    elems.append(meta_tbl)
    elems.append(Spacer(1, 1.5*cm))
    elems.append(HRFlowable(width="100%", thickness=1, color=BORDER))
    elems.append(Spacer(1, 0.4*cm))
    elems.append(Paragraph(
        "This document covers all functional, UI, and integration test cases "
        "for the Musafirah Women Carpooling Mobile Application. "
        "Test cases are organized by module and role (Passenger, Driver, Admin).",
        s("Normal", fontSize=9, textColor=colors.grey, alignment=TA_CENTER, leading=14)
    ))
    elems.append(PageBreak())
    return elems


# ── Table of Contents ─────────────────────────────────────────────────────────

def toc():
    elems = []
    elems.append(section_header("TABLE OF CONTENTS"))
    elems.append(Spacer(1, 0.4*cm))
    sections = [
        ("1", "Splash Screen & App Launch"),
        ("2", "User Role Selection"),
        ("3", "Authentication – Login (Email & Phone)"),
        ("4", "Passenger Registration & Signup"),
        ("5", "Driver Registration & Signup"),
        ("6", "Document Verification – CNIC"),
        ("7", "Document Verification – Driver License"),
        ("8", "Document Verification – Vehicle Info"),
        ("9", "Selfie Verification"),
        ("10","Passenger Dashboard"),
        ("11","Driver Dashboard"),
        ("12","Ride Booking Flow (Passenger)"),
        ("13","Ride Acceptance Flow (Driver)"),
        ("14","Driver Navigation & Trip Completion"),
        ("15","Real-Time Chat"),
        ("16","Passenger Profile & Edit Profile"),
        ("17","Driver Profile"),
        ("18","Wallet & Transaction History"),
        ("19","Account Status – Pending / Rejected / Blocked"),
        ("20","Admin – Login & Dashboard"),
        ("21","Admin – Driver Management"),
        ("22","Admin – Rider Management"),
        ("23","Terms & Conditions / Privacy Policy"),
        ("24","Edge Cases & Error Handling"),
    ]
    toc_data = [[Paragraph(f"{n}. {t}", body_style), Paragraph("", body_style)]
                for n, t in sections]
    toc_tbl = Table(toc_data, colWidths=[14*cm, 2.5*cm])
    toc_tbl.setStyle(TableStyle([
        ("ROWBACKGROUNDS",(0,0),(-1,-1),[colors.white, GREY_BG]),
        ("TOPPADDING",   (0,0),(-1,-1), 5),
        ("BOTTOMPADDING",(0,0),(-1,-1), 5),
        ("LEFTPADDING",  (0,0),(-1,-1), 8),
        ("LINEBELOW",    (0,0),(-1,-1), 0.3, BORDER),
    ]))
    elems.append(toc_tbl)
    elems.append(PageBreak())
    return elems


# ── Test Case Data ────────────────────────────────────────────────────────────

def all_sections():
    elems = []

    # ── 1. Splash Screen ─────────────────────────────────────────────────────
    elems += [section_header("1. Splash Screen & App Launch"), Spacer(1, 0.3*cm)]
    elems.append(tc_table([
        {"tc_id":"TC-SP-01","description":"App launches and splash screen is displayed",
         "preconditions":"App installed on device",
         "steps":"1. Open Musafirah app",
         "expected":"Musafirah logo and tagline appear with animation",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-SP-02","description":"Auto-navigation after 3 seconds",
         "preconditions":"Splash screen displayed",
         "steps":"1. Wait 3 seconds on splash screen",
         "expected":"App navigates automatically to User Choice screen",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-SP-03","description":"Tagline text is correct",
         "preconditions":"App launched",
         "steps":"1. Observe splash screen text",
         "expected":"Tagline reads: 'Your safe journey, synchronized'",
         "priority":"Low","status":"Pass"},
    ]))
    elems.append(Spacer(1, 0.5*cm))

    # ── 2. User Choice ───────────────────────────────────────────────────────
    elems += [section_header("2. User Role Selection"), Spacer(1, 0.3*cm)]
    elems.append(tc_table([
        {"tc_id":"TC-UC-01","description":"Three role cards displayed",
         "preconditions":"User on User Choice screen",
         "steps":"1. Navigate to User Choice screen",
         "expected":"Passenger, Driver, and Admin cards are visible",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-UC-02","description":"Passenger Login button navigates correctly",
         "preconditions":"User on User Choice screen",
         "steps":"1. Tap 'Log In' on Passenger card",
         "expected":"Navigates to Email Password Login screen with 'Passenger' role label",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-UC-03","description":"Driver Login button navigates correctly",
         "preconditions":"User on User Choice screen",
         "steps":"1. Tap 'Log In' on Driver card",
         "expected":"Navigates to Email Password Login screen with 'Driver' role label",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-UC-04","description":"Passenger Sign Up button navigates correctly",
         "preconditions":"User on User Choice screen",
         "steps":"1. Tap 'Sign Up' on Passenger card",
         "expected":"Navigates to Passenger Email Signup screen",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-UC-05","description":"Driver Sign Up button navigates correctly",
         "preconditions":"User on User Choice screen",
         "steps":"1. Tap 'Sign Up' on Driver card",
         "expected":"Navigates to Driver Email Signup screen",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-UC-06","description":"Admin card has no Sign Up button",
         "preconditions":"User on User Choice screen",
         "steps":"1. Observe Admin card",
         "expected":"Only 'Log In' button visible; no 'Sign Up' button on Admin card",
         "priority":"Medium","status":"Pass"},
        {"tc_id":"TC-UC-07","description":"Admin Login button navigates correctly",
         "preconditions":"User on User Choice screen",
         "steps":"1. Tap 'Log In' on Admin card",
         "expected":"Navigates to Admin Login screen",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-UC-08","description":"Entry animations play on screen load",
         "preconditions":"User navigated from Splash",
         "steps":"1. Observe cards on screen entry",
         "expected":"Cards slide and fade in smoothly",
         "priority":"Low","status":"Pass"},
    ]))
    elems.append(Spacer(1, 0.5*cm))

    # ── 3. Authentication ─────────────────────────────────────────────────────
    elems += [section_header("3. Authentication – Login (Email & Phone)"), Spacer(1, 0.3*cm)]
    elems.append(tc_table([
        {"tc_id":"TC-AU-01","description":"Login screen shows Passenger role badge",
         "preconditions":"Tapped Passenger login from User Choice",
         "steps":"1. Observe header badge on Email Login screen",
         "expected":"Badge shows 'Passenger Login' with person icon",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-AU-02","description":"Login screen shows Driver role badge",
         "preconditions":"Tapped Driver login from User Choice",
         "steps":"1. Observe header badge on Email Login screen",
         "expected":"Badge shows 'Driver Login' with car icon",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-AU-03","description":"Welcome text is role-specific",
         "preconditions":"Role passed to Email Login screen",
         "steps":"1. Observe welcome heading",
         "expected":"Shows 'Welcome Aboard, Passenger!' or 'Welcome Aboard, Driver!'",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-AU-04","description":"Empty email field shows validation error",
         "preconditions":"Email Login screen open",
         "steps":"1. Leave email empty\n2. Tap Log In",
         "expected":"Validation error: 'Email is required'",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-AU-05","description":"Empty password field shows validation error",
         "preconditions":"Email Login screen open",
         "steps":"1. Enter valid email\n2. Leave password empty\n3. Tap Log In",
         "expected":"Validation error: 'Password is required'",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-AU-06","description":"Wrong credentials show error snackbar",
         "preconditions":"Email Login screen open",
         "steps":"1. Enter wrong email/password\n2. Tap Log In",
         "expected":"Red snackbar appears with Firebase error message",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-AU-07","description":"Valid passenger credentials navigate to Passenger Dashboard",
         "preconditions":"Approved passenger account exists",
         "steps":"1. Enter correct email and password\n2. Tap Log In",
         "expected":"Navigates to Passenger Dashboard screen",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-AU-08","description":"Valid driver credentials navigate to Driver Dashboard",
         "preconditions":"Approved driver account exists",
         "steps":"1. Enter correct driver email and password\n2. Tap Log In",
         "expected":"Navigates to Driver Dashboard screen",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-AU-09","description":"Password visibility toggle works",
         "preconditions":"Email Login screen open",
         "steps":"1. Enter password\n2. Tap eye icon",
         "expected":"Password text toggles between hidden and visible",
         "priority":"Medium","status":"Pass"},
        {"tc_id":"TC-AU-10","description":"Phone login – empty phone shows error",
         "preconditions":"Phone Login screen open",
         "steps":"1. Leave phone number empty\n2. Tap Send OTP",
         "expected":"Validation error shown for empty phone",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-AU-11","description":"Phone login – invalid phone (< 7 digits) shows error",
         "preconditions":"Phone Login screen open",
         "steps":"1. Enter 5-digit number\n2. Tap Send OTP",
         "expected":"Validation error: minimum 7 digits required",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-AU-12","description":"Phone login – non-numeric input shows error",
         "preconditions":"Phone Login screen open",
         "steps":"1. Enter letters in phone field\n2. Tap Send OTP",
         "expected":"Validation error: digits only",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-AU-13","description":"Valid phone number sends OTP",
         "preconditions":"Phone Login screen open",
         "steps":"1. Enter valid 10-digit phone\n2. Tap Send OTP",
         "expected":"OTP field appears; success message shown",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-AU-14","description":"OTP verification with valid 6-digit code",
         "preconditions":"OTP sent successfully",
         "steps":"1. Enter correct 6-digit OTP\n2. Tap Verify",
         "expected":"Navigates to appropriate dashboard",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-AU-15","description":"OTP with wrong code shows error",
         "preconditions":"OTP sent successfully",
         "steps":"1. Enter wrong OTP\n2. Tap Verify",
         "expected":"Error snackbar shown",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-AU-16","description":"Resend OTP button works",
         "preconditions":"OTP already sent",
         "steps":"1. Tap 'Resend OTP'",
         "expected":"New OTP is sent, confirmation shown",
         "priority":"Medium","status":"Pass"},
        {"tc_id":"TC-AU-17","description":"Back button returns to previous screen",
         "preconditions":"Any login screen open",
         "steps":"1. Tap back arrow",
         "expected":"Returns to previous screen without errors",
         "priority":"Medium","status":"Pass"},
        {"tc_id":"TC-AU-18","description":"Loading spinner shown during login",
         "preconditions":"Valid credentials entered",
         "steps":"1. Tap Log In and observe button",
         "expected":"Button replaced by loading spinner during authentication",
         "priority":"Medium","status":"Pass"},
    ]))
    elems.append(Spacer(1, 0.5*cm))

    # ── 4. Passenger Signup ───────────────────────────────────────────────────
    elems += [section_header("4. Passenger Registration & Signup"), Spacer(1, 0.3*cm)]
    elems.append(tc_table([
        {"tc_id":"TC-PS-01","description":"Empty name field shows validation error",
         "preconditions":"Passenger Signup screen open",
         "steps":"1. Leave name empty\n2. Tap Sign Up",
         "expected":"Validation error: name is required",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-PS-02","description":"Invalid email format shows error",
         "preconditions":"Passenger Signup screen open",
         "steps":"1. Enter 'notanemail'\n2. Tap Sign Up",
         "expected":"Validation error: invalid email format",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-PS-03","description":"Password shorter than 6 chars shows error",
         "preconditions":"Passenger Signup screen open",
         "steps":"1. Enter password 'abc'\n2. Tap Sign Up",
         "expected":"Validation error: minimum 6 characters",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-PS-04","description":"Mismatched passwords show error",
         "preconditions":"Passenger Signup screen open",
         "steps":"1. Enter password 'pass123'\n2. Enter confirm 'pass456'\n3. Tap Sign Up",
         "expected":"Validation error: passwords do not match",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-PS-05","description":"Duplicate email shows Firebase error",
         "preconditions":"Email already registered",
         "steps":"1. Enter existing email\n2. Fill other fields\n3. Tap Sign Up",
         "expected":"Error snackbar: email already in use",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-PS-06","description":"Valid data creates account and navigates to CNIC",
         "preconditions":"New unique email",
         "steps":"1. Fill all valid fields\n2. Tap Sign Up",
         "expected":"Account created; navigates to CNIC Verification screen",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-PS-07","description":"Account is created with 'pending' status",
         "preconditions":"Signup completed successfully",
         "steps":"1. Check Firestore Passengers collection after signup",
         "expected":"Status field = 'pending'",
         "priority":"High","status":"Pass"},
    ]))
    elems.append(Spacer(1, 0.5*cm))

    # ── 5. Driver Signup ──────────────────────────────────────────────────────
    elems += [section_header("5. Driver Registration & Signup"), Spacer(1, 0.3*cm)]
    elems.append(tc_table([
        {"tc_id":"TC-DS-01","description":"Empty name field shows validation error",
         "preconditions":"Driver Signup screen open",
         "steps":"1. Leave name empty\n2. Tap Sign Up",
         "expected":"Validation error: name is required",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-DS-02","description":"Invalid email shows error",
         "preconditions":"Driver Signup screen open",
         "steps":"1. Enter invalid email\n2. Tap Sign Up",
         "expected":"Validation error: invalid email format",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-DS-03","description":"Empty phone shows error",
         "preconditions":"Driver Signup screen open",
         "steps":"1. Leave phone empty\n2. Tap Sign Up",
         "expected":"Validation error: phone is required",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-DS-04","description":"Password shorter than 6 chars shows error",
         "preconditions":"Driver Signup screen open",
         "steps":"1. Enter short password\n2. Tap Sign Up",
         "expected":"Validation error: minimum 6 characters",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-DS-05","description":"Valid data creates account and navigates to License",
         "preconditions":"New unique email",
         "steps":"1. Fill all valid fields\n2. Tap Sign Up",
         "expected":"Account created; navigates to Driver License screen",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-DS-06","description":"Driver account created with 'pending' status",
         "preconditions":"Signup completed",
         "steps":"1. Check Firestore Drivers collection",
         "expected":"Status field = 'pending'",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-DS-07","description":"Duplicate email shows Firebase error",
         "preconditions":"Email already registered",
         "steps":"1. Enter existing email\n2. Tap Sign Up",
         "expected":"Error snackbar: email already in use",
         "priority":"High","status":"Pass"},
    ]))
    elems.append(Spacer(1, 0.5*cm))

    # ── 6. CNIC Verification ──────────────────────────────────────────────────
    elems += [section_header("6. Document Verification – CNIC"), Spacer(1, 0.3*cm)]
    elems.append(tc_table([
        {"tc_id":"TC-CN-01","description":"Upload front CNIC image triggers OCR",
         "preconditions":"CNIC screen open",
         "steps":"1. Upload front CNIC image from gallery",
         "expected":"OCR extracts name, DOB, CNIC number and auto-fills fields",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-CN-02","description":"Upload back CNIC image",
         "preconditions":"Front CNIC uploaded",
         "steps":"1. Upload back CNIC image",
         "expected":"Back image displayed; no errors",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-CN-03","description":"CNIC number extracted in correct format",
         "preconditions":"Clear CNIC image uploaded",
         "steps":"1. Upload CNIC front image\n2. Check CNIC number field",
         "expected":"CNIC number follows format: XXXXX-XXXXXXX-X",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-CN-04","description":"Dates extracted correctly",
         "preconditions":"Clear CNIC image uploaded",
         "steps":"1. Upload CNIC front image\n2. Check date fields",
         "expected":"Issue date and expiry date auto-filled correctly",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-CN-05","description":"Submitting without front image shows error",
         "preconditions":"CNIC screen open",
         "steps":"1. Skip front CNIC upload\n2. Tap Submit",
         "expected":"Error: front CNIC image is required",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-CN-06","description":"Emergency relation dropdown shows options",
         "preconditions":"CNIC screen open",
         "steps":"1. Tap Emergency Relation dropdown",
         "expected":"Options: Family member, Spouse, Friend",
         "priority":"Medium","status":"Pass"},
        {"tc_id":"TC-CN-07","description":"Submitting with all valid fields saves to Firestore",
         "preconditions":"All fields filled",
         "steps":"1. Complete all fields\n2. Tap Submit",
         "expected":"Data saved to Firestore; navigates to Selfie screen",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-CN-08","description":"registrationStep updated to 'cnic_completed'",
         "preconditions":"CNIC submission successful",
         "steps":"1. Check Firestore after CNIC submission",
         "expected":"registrationStep = 'cnic_completed'",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-CN-09","description":"Logout shows confirmation dialog",
         "preconditions":"CNIC screen open",
         "steps":"1. Tap logout icon",
         "expected":"Confirmation dialog: 'Are you sure you want to logout?'",
         "priority":"Medium","status":"Pass"},
    ]))
    elems.append(Spacer(1, 0.5*cm))

    # ── 7. Driver License ─────────────────────────────────────────────────────
    elems += [section_header("7. Document Verification – Driver License"), Spacer(1, 0.3*cm)]
    elems.append(tc_table([
        {"tc_id":"TC-DL-01","description":"Upload front license image triggers OCR",
         "preconditions":"Driver License screen open",
         "steps":"1. Upload front license image from gallery",
         "expected":"OCR extracts license number and expiry date; fields auto-filled",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-DL-02","description":"License number extracted in correct format",
         "preconditions":"Clear license image uploaded",
         "steps":"1. Upload license front\n2. Check license number field",
         "expected":"Format: XXXXX-XXXXXXX-X#XXX",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-DL-03","description":"Upload back license image",
         "preconditions":"Front license uploaded",
         "steps":"1. Upload back license image",
         "expected":"Back image displayed without errors",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-DL-04","description":"Submit without front image shows error",
         "preconditions":"License screen open",
         "steps":"1. Tap Submit without uploading front",
         "expected":"Validation error: front license image required",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-DL-05","description":"Valid license submission navigates to Vehicle Info",
         "preconditions":"Both license images uploaded",
         "steps":"1. Upload both images\n2. Tap Next",
         "expected":"Navigates to Driver Vehicle Info screen",
         "priority":"High","status":"Pass"},
    ]))
    elems.append(Spacer(1, 0.5*cm))

    # ── 8. Vehicle Info ───────────────────────────────────────────────────────
    elems += [section_header("8. Document Verification – Vehicle Info"), Spacer(1, 0.3*cm)]
    elems.append(tc_table([
        {"tc_id":"TC-VI-01","description":"Submit without plate number shows error",
         "preconditions":"Vehicle Info screen open",
         "steps":"1. Leave plate number empty\n2. Tap Submit",
         "expected":"Validation error: plate number is required",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-VI-02","description":"Submit without car photo shows error",
         "preconditions":"Vehicle Info screen open",
         "steps":"1. Skip car photo upload\n2. Tap Submit",
         "expected":"Validation error: car image is required",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-VI-03","description":"Car capacity defaults to 4",
         "preconditions":"Vehicle Info screen open",
         "steps":"1. Observe capacity field on load",
         "expected":"Capacity field pre-filled with '4'",
         "priority":"Low","status":"Pass"},
        {"tc_id":"TC-VI-04","description":"Valid vehicle data saves to Firestore",
         "preconditions":"All fields filled including plate and photo",
         "steps":"1. Fill car model, year, color, plate, capacity\n2. Upload photo\n3. Tap Submit",
         "expected":"Vehicle data saved; navigates to CNIC screen",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-VI-05","description":"registrationStep updated to 'vehicle_completed'",
         "preconditions":"Vehicle submission successful",
         "steps":"1. Check Firestore after vehicle submission",
         "expected":"registrationStep = 'vehicle_completed'",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-VI-06","description":"Car image uploaded from gallery",
         "preconditions":"Vehicle Info screen open",
         "steps":"1. Tap upload car photo\n2. Select from gallery",
         "expected":"Image appears in preview",
         "priority":"Medium","status":"Pass"},
    ]))
    elems.append(Spacer(1, 0.5*cm))

    # ── 9. Selfie Verification ────────────────────────────────────────────────
    elems += [section_header("9. Selfie Verification"), Spacer(1, 0.3*cm)]
    elems.append(tc_table([
        {"tc_id":"TC-SV-01","description":"Camera preview opens on screen load",
         "preconditions":"Selfie screen open with camera permission",
         "steps":"1. Navigate to Selfie screen",
         "expected":"Front-facing camera preview displayed",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-SV-02","description":"Submitting without selfie shows error",
         "preconditions":"Selfie screen open",
         "steps":"1. Tap Submit without taking/uploading selfie",
         "expected":"Validation error: selfie image required",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-SV-03","description":"Capture from camera works",
         "preconditions":"Camera permission granted",
         "steps":"1. Tap camera button to take selfie",
         "expected":"Selfie captured and displayed in circular preview",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-SV-04","description":"Upload from gallery works",
         "preconditions":"Selfie screen open",
         "steps":"1. Tap gallery option\n2. Select image",
         "expected":"Selected image displayed in preview",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-SV-05","description":"Successful submission saves to Firestore",
         "preconditions":"Selfie captured",
         "steps":"1. Capture selfie\n2. Tap Submit",
         "expected":"Selfie saved; isVerified = false; navigates to dashboard",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-SV-06","description":"Tips section is visible",
         "preconditions":"Selfie screen open",
         "steps":"1. Observe tips panel",
         "expected":"Tips shown: good lighting, look at camera, no glasses, full face",
         "priority":"Low","status":"Pass"},
        {"tc_id":"TC-SV-07","description":"Logout shows confirmation dialog",
         "preconditions":"Selfie screen open",
         "steps":"1. Tap logout",
         "expected":"Confirmation dialog appears before logging out",
         "priority":"Medium","status":"Pass"},
    ]))
    elems.append(Spacer(1, 0.5*cm))

    # ── 10. Passenger Dashboard ───────────────────────────────────────────────
    elems += [section_header("10. Passenger Dashboard"), Spacer(1, 0.3*cm)]
    elems.append(tc_table([
        {"tc_id":"TC-PD-01","description":"Dashboard loads with map and user location",
         "preconditions":"Approved passenger logged in, location permission granted",
         "steps":"1. Open passenger dashboard",
         "expected":"Map shows current location pin; welcome message visible",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-PD-02","description":"Pending user redirected to Pending screen",
         "preconditions":"Passenger with status 'pending' logs in",
         "steps":"1. Login as pending passenger",
         "expected":"Redirected to User Pending screen automatically",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-PD-03","description":"Blocked user redirected to Pending screen",
         "preconditions":"Passenger with status 'blocked' logs in",
         "steps":"1. Login as blocked passenger",
         "expected":"Redirected to User Pending screen with blocked message",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-PD-04","description":"Destination input shows autocomplete suggestions",
         "preconditions":"Passenger dashboard open",
         "steps":"1. Tap destination field\n2. Type a location name",
         "expected":"Autocomplete suggestions displayed from OSM",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-PD-05","description":"Fare estimate calculated and displayed",
         "preconditions":"Origin and destination entered",
         "steps":"1. Enter pickup and destination\n2. Observe fare display",
         "expected":"Estimated fare shown in PKR",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-PD-06","description":"Popular destinations carousel is displayed",
         "preconditions":"Dashboard loaded",
         "steps":"1. Scroll home page",
         "expected":"Popular destination cards visible and scrollable",
         "priority":"Medium","status":"Pass"},
        {"tc_id":"TC-PD-07","description":"Bottom navigation – Wallet tab works",
         "preconditions":"Passenger dashboard open",
         "steps":"1. Tap Wallet tab in bottom navigation",
         "expected":"Navigates to Wallet History screen",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-PD-08","description":"Bottom navigation – Profile tab works",
         "preconditions":"Passenger dashboard open",
         "steps":"1. Tap Profile tab",
         "expected":"Navigates to Rider Profile screen",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-PD-09","description":"'Find Ride' with destination navigates to driver list",
         "preconditions":"Destination entered",
         "steps":"1. Enter destination\n2. Tap Find/Book Ride",
         "expected":"Navigates to Passenger Ride Selection screen",
         "priority":"High","status":"Pass"},
    ]))
    elems.append(Spacer(1, 0.5*cm))

    # ── 11. Driver Dashboard ──────────────────────────────────────────────────
    elems += [section_header("11. Driver Dashboard"), Spacer(1, 0.3*cm)]
    elems.append(tc_table([
        {"tc_id":"TC-DD-01","description":"Dashboard loads with map and driver location",
         "preconditions":"Approved driver logged in, location permission granted",
         "steps":"1. Open driver dashboard",
         "expected":"Map displayed with current driver location pin",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-DD-02","description":"Pending driver redirected to Pending screen",
         "preconditions":"Driver with status 'pending'",
         "steps":"1. Login as pending driver",
         "expected":"Redirected to User Pending screen",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-DD-03","description":"Recent trips list loads",
         "preconditions":"Driver has past trips",
         "steps":"1. Open driver dashboard",
         "expected":"Recent trips displayed with dates and fares",
         "priority":"Medium","status":"Pass"},
        {"tc_id":"TC-DD-04","description":"Ride Requests tab navigates correctly",
         "preconditions":"Driver dashboard open",
         "steps":"1. Tap 'Requests' in bottom nav",
         "expected":"Navigates to Driver Ride Requests screen",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-DD-05","description":"Active Rides tab navigates correctly",
         "preconditions":"Driver dashboard open",
         "steps":"1. Tap 'Active Rides' in bottom nav",
         "expected":"Navigates to Driver Active Rides screen",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-DD-06","description":"Wallet tab navigates correctly",
         "preconditions":"Driver dashboard open",
         "steps":"1. Tap Wallet tab",
         "expected":"Navigates to Driver Wallet screen",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-DD-07","description":"Profile tab navigates correctly",
         "preconditions":"Driver dashboard open",
         "steps":"1. Tap Profile tab",
         "expected":"Navigates to Driver Profile screen",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-DD-08","description":"Start location autocomplete works",
         "preconditions":"Driver dashboard open",
         "steps":"1. Type in start location field",
         "expected":"OSM autocomplete suggestions appear",
         "priority":"High","status":"Pass"},
    ]))
    elems.append(Spacer(1, 0.5*cm))

    # ── 12. Ride Booking Flow ─────────────────────────────────────────────────
    elems += [section_header("12. Ride Booking Flow (Passenger)"), Spacer(1, 0.3*cm)]
    elems.append(tc_table([
        {"tc_id":"TC-RB-01","description":"Ride Selection screen shows available drivers",
         "preconditions":"Destination entered, navigate to Ride Selection",
         "steps":"1. Set pickup and destination\n2. Tap find ride",
         "expected":"List of nearby available drivers displayed",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-RB-02","description":"Drivers filtered by proximity (within 15 km)",
         "preconditions":"Ride Selection screen open",
         "steps":"1. Observe driver list",
         "expected":"Only drivers within 15 km of pickup are shown",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-RB-03","description":"Driver card shows name, rating, vehicle info",
         "preconditions":"Drivers listed on Ride Selection",
         "steps":"1. Observe driver cards",
         "expected":"Each card shows driver name, star rating, vehicle model, plate",
         "priority":"Medium","status":"Pass"},
        {"tc_id":"TC-RB-04","description":"Selecting a driver opens Ride Booking screen",
         "preconditions":"Driver list visible",
         "steps":"1. Tap on a driver card",
         "expected":"Navigates to Ride Booking screen with driver details",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-RB-05","description":"Ride Booking screen shows map with route",
         "preconditions":"Ride Booking screen open",
         "steps":"1. Observe map on Ride Booking screen",
         "expected":"Map shows pickup and dropoff markers with route",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-RB-06","description":"Estimated fare displayed on booking screen",
         "preconditions":"Ride Booking screen open",
         "steps":"1. Observe fare section",
         "expected":"Fare amount in PKR is clearly displayed",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-RB-07","description":"Confirm Ride navigates to Ride Confirmed screen",
         "preconditions":"Ride Booking screen open",
         "steps":"1. Tap 'Confirm Ride' button",
         "expected":"Navigates to Ride Confirmed screen",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-RB-08","description":"Cancel ride on selection screen shows confirmation",
         "preconditions":"Ride Selection screen open",
         "steps":"1. Tap Cancel button",
         "expected":"Confirmation dialog appears before cancelling",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-RB-09","description":"No available drivers shows empty state",
         "preconditions":"No drivers in area",
         "steps":"1. Enter remote destination with no drivers",
         "expected":"Empty state message shown",
         "priority":"Medium","status":"Pass"},
        {"tc_id":"TC-RB-10","description":"Ride Confirmed screen shows driver details",
         "preconditions":"Ride confirmed",
         "steps":"1. Observe Ride Confirmed screen",
         "expected":"Driver name, photo, rating, vehicle and route info visible",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-RB-11","description":"Track Ride button opens live tracking",
         "preconditions":"Ride Confirmed screen open",
         "steps":"1. Tap 'Track Ride'",
         "expected":"Navigates to Passenger Live Tracking screen",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-RB-12","description":"Cancel confirmed ride shows dialog",
         "preconditions":"Ride Confirmed screen open",
         "steps":"1. Tap Cancel Ride",
         "expected":"Confirmation dialog; ride cancelled in Firestore on confirm",
         "priority":"High","status":"Pass"},
    ]))
    elems.append(Spacer(1, 0.5*cm))

    # ── 13. Driver Ride Acceptance ────────────────────────────────────────────
    elems += [section_header("13. Ride Acceptance Flow (Driver)"), Spacer(1, 0.3*cm)]
    elems.append(tc_table([
        {"tc_id":"TC-RA-01","description":"Ride Requests screen shows nearby passengers",
         "preconditions":"Driver on Ride Requests screen",
         "steps":"1. Navigate to Ride Requests screen",
         "expected":"List of nearby ride requests displayed",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-RA-02","description":"Requests filtered within 15 km of driver",
         "preconditions":"Ride Requests screen open",
         "steps":"1. Observe request list",
         "expected":"Only passengers within proximity are shown",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-RA-03","description":"Accept ride updates driver capacity",
         "preconditions":"Ride request visible",
         "steps":"1. Tap Accept on a ride request",
         "expected":"Driver capacity decremented; ride accepted in Firestore",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-RA-04","description":"Accept ride navigates to Navigation screen",
         "preconditions":"Ride accepted",
         "steps":"1. Accept a ride request",
         "expected":"Navigates to Driver Navigation screen with route",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-RA-05","description":"Decline ride removes it from list",
         "preconditions":"Ride request visible",
         "steps":"1. Tap Decline on a request",
         "expected":"Request removed from driver's list",
         "priority":"Medium","status":"Pass"},
        {"tc_id":"TC-RA-06","description":"Driver with zero capacity cannot accept rides",
         "preconditions":"Driver available_seats = 0",
         "steps":"1. Try to accept a ride",
         "expected":"Error shown: no available seats",
         "priority":"High","status":"Pass"},
    ]))
    elems.append(Spacer(1, 0.5*cm))

    # ── 14. Driver Navigation ─────────────────────────────────────────────────
    elems += [section_header("14. Driver Navigation & Trip Completion"), Spacer(1, 0.3*cm)]
    elems.append(tc_table([
        {"tc_id":"TC-DN-01","description":"Navigation screen shows route on map",
         "preconditions":"Driver accepted a ride",
         "steps":"1. Observe map on Navigation screen",
         "expected":"Map shows start and end points with route drawn",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-DN-02","description":"Navigation steps displayed",
         "preconditions":"Navigation screen open",
         "steps":"1. Observe step indicator",
         "expected":"Turn-by-turn steps shown with current step highlighted",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-DN-03","description":"Call passenger button works",
         "preconditions":"Navigation screen open",
         "steps":"1. Tap call button",
         "expected":"Device dialer opens with passenger phone number",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-DN-04","description":"Chat button opens chat screen",
         "preconditions":"Navigation screen open",
         "steps":"1. Tap chat icon",
         "expected":"Navigates to Chat screen with passenger name",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-DN-05","description":"SOS button shows emergency dialog",
         "preconditions":"Navigation screen open",
         "steps":"1. Tap SOS button",
         "expected":"Emergency warning dialog appears",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-DN-06","description":"Complete trip navigates to Payment screen",
         "preconditions":"Navigation screen open",
         "steps":"1. Tap 'Complete Trip' or finish navigation",
         "expected":"Navigates to Driver Payment screen with fare",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-DN-07","description":"Payment screen shows correct fare",
         "preconditions":"Trip completed, on Payment screen",
         "steps":"1. Observe fare on Payment screen",
         "expected":"Fare matches the agreed amount in PKR",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-DN-08","description":"Return to Dashboard from Payment screen",
         "preconditions":"Payment screen open",
         "steps":"1. Tap 'Return to Dashboard'",
         "expected":"Navigates back to Driver Dashboard; route cleared",
         "priority":"High","status":"Pass"},
    ]))
    elems.append(Spacer(1, 0.5*cm))

    # ── 15. Chat ──────────────────────────────────────────────────────────────
    elems += [section_header("15. Real-Time Chat"), Spacer(1, 0.3*cm)]
    elems.append(tc_table([
        {"tc_id":"TC-CH-01","description":"Chat screen shows peer name in header",
         "preconditions":"Chat screen opened from navigation or ride",
         "steps":"1. Open chat screen",
         "expected":"Peer name displayed in app bar",
         "priority":"Medium","status":"Pass"},
        {"tc_id":"TC-CH-02","description":"Empty message cannot be sent",
         "preconditions":"Chat screen open",
         "steps":"1. Leave message field empty\n2. Tap Send",
         "expected":"Message not sent; no empty bubble added",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-CH-03","description":"Sent messages appear on right side",
         "preconditions":"Chat screen open",
         "steps":"1. Type a message\n2. Tap Send",
         "expected":"Message appears on right with timestamp",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-CH-04","description":"Input cleared after sending",
         "preconditions":"Chat screen open",
         "steps":"1. Type and send a message",
         "expected":"Text input field is cleared after send",
         "priority":"Medium","status":"Pass"},
        {"tc_id":"TC-CH-05","description":"Quick reply buttons send predefined messages",
         "preconditions":"Passenger Chat screen open",
         "steps":"1. Tap a quick reply chip (e.g. 'On my way!')",
         "expected":"Predefined message sent and appears in chat",
         "priority":"Medium","status":"Pass"},
        {"tc_id":"TC-CH-06","description":"Driver greeting auto-seeded on load",
         "preconditions":"Passenger Chat screen opened",
         "steps":"1. Open Passenger Chat screen",
         "expected":"Driver greeting message appears after ~600ms",
         "priority":"Low","status":"Pass"},
    ]))
    elems.append(Spacer(1, 0.5*cm))

    # ── 16. Passenger Profile ─────────────────────────────────────────────────
    elems += [section_header("16. Passenger Profile & Edit Profile"), Spacer(1, 0.3*cm)]
    elems.append(tc_table([
        {"tc_id":"TC-PP-01","description":"Profile screen loads with user data",
         "preconditions":"Approved passenger logged in",
         "steps":"1. Navigate to Profile screen",
         "expected":"Name, photo, rating, and total rides displayed",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-PP-02","description":"Ride history displayed on profile",
         "preconditions":"Passenger has past rides",
         "steps":"1. Scroll profile screen",
         "expected":"Ride history list with dates, fare, driver name",
         "priority":"Medium","status":"Pass"},
        {"tc_id":"TC-PP-03","description":"Edit Profile navigates to edit screen",
         "preconditions":"Profile screen open",
         "steps":"1. Tap 'Edit Profile'",
         "expected":"Navigates to Edit Profile screen with pre-filled fields",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-PP-04","description":"Save with empty name shows validation error",
         "preconditions":"Edit Profile screen open",
         "steps":"1. Clear name field\n2. Tap Save",
         "expected":"Validation error: name is required",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-PP-05","description":"Save with invalid email shows error",
         "preconditions":"Edit Profile screen open",
         "steps":"1. Enter invalid email\n2. Tap Save",
         "expected":"Validation error: invalid email format",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-PP-06","description":"Update profile photo from camera",
         "preconditions":"Edit Profile screen open",
         "steps":"1. Tap profile photo\n2. Select Camera\n3. Take photo",
         "expected":"New photo shown in preview",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-PP-07","description":"Valid profile save updates Firestore",
         "preconditions":"Edit Profile screen open",
         "steps":"1. Update name\n2. Tap Save",
         "expected":"Data saved to Firestore; success toast shown; navigates back",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-PP-08","description":"Logout shows confirmation dialog",
         "preconditions":"Profile screen open",
         "steps":"1. Tap Logout button",
         "expected":"Confirmation dialog: 'Are you sure you want to logout?'",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-PP-09","description":"Logout signs out and navigates to UserChoice",
         "preconditions":"Logout confirmed",
         "steps":"1. Confirm logout in dialog",
         "expected":"Firebase signed out; navigates to User Choice screen",
         "priority":"High","status":"Pass"},
    ]))
    elems.append(Spacer(1, 0.5*cm))

    # ── 17. Driver Profile ────────────────────────────────────────────────────
    elems += [section_header("17. Driver Profile"), Spacer(1, 0.3*cm)]
    elems.append(tc_table([
        {"tc_id":"TC-DP-01","description":"Driver profile loads with correct data",
         "preconditions":"Approved driver logged in",
         "steps":"1. Navigate to Driver Profile",
         "expected":"Driver name, photo, rating, total rides displayed",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-DP-02","description":"Vehicle information card visible",
         "preconditions":"Driver has vehicle info saved",
         "steps":"1. Observe vehicle section on profile",
         "expected":"Car model, color, plate number displayed",
         "priority":"Medium","status":"Pass"},
        {"tc_id":"TC-DP-03","description":"Edit Profile navigates to driver edit screen",
         "preconditions":"Driver profile open",
         "steps":"1. Tap Edit Profile",
         "expected":"Navigates to Driver Edit Profile screen",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-DP-04","description":"Logout signs out driver",
         "preconditions":"Driver profile open",
         "steps":"1. Tap Logout\n2. Confirm",
         "expected":"Signed out; navigates to Login screen",
         "priority":"High","status":"Pass"},
    ]))
    elems.append(Spacer(1, 0.5*cm))

    # ── 18. Wallet ────────────────────────────────────────────────────────────
    elems += [section_header("18. Wallet & Transaction History"), Spacer(1, 0.3*cm)]
    elems.append(tc_table([
        {"tc_id":"TC-WL-01","description":"Wallet screen loads with balance",
         "preconditions":"Logged-in passenger on Wallet screen",
         "steps":"1. Navigate to Wallet screen",
         "expected":"Balance card with PKR amount displayed",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-WL-02","description":"Transactions tab shows transaction history",
         "preconditions":"Wallet screen open",
         "steps":"1. Tap Transactions tab",
         "expected":"List of transactions with dates and amounts",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-WL-03","description":"Ride History tab shows past rides",
         "preconditions":"Wallet screen open",
         "steps":"1. Tap Ride History tab",
         "expected":"List of completed rides with fares and driver names",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-WL-04","description":"Add Funds button adds PKR 500",
         "preconditions":"Wallet screen open",
         "steps":"1. Tap 'Add Funds' button",
         "expected":"Balance increases by PKR 500",
         "priority":"Medium","status":"Pass"},
        {"tc_id":"TC-WL-05","description":"Driver wallet shows earnings",
         "preconditions":"Driver on Wallet screen",
         "steps":"1. Navigate to Driver Wallet",
         "expected":"Total balance and earnings displayed",
         "priority":"High","status":"Pass"},
    ]))
    elems.append(Spacer(1, 0.5*cm))

    # ── 19. Account Status ────────────────────────────────────────────────────
    elems += [section_header("19. Account Status – Pending / Rejected / Blocked"), Spacer(1, 0.3*cm)]
    elems.append(tc_table([
        {"tc_id":"TC-AS-01","description":"Pending screen shows correct message",
         "preconditions":"User with 'pending' status logs in",
         "steps":"1. Login with pending account",
         "expected":"Pending screen shows '24-48 hours' approval message",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-AS-02","description":"Rejected screen shows rejection message",
         "preconditions":"User with 'rejected' status",
         "steps":"1. Login with rejected account",
         "expected":"Screen shows 'Application rejected' with contact support option",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-AS-03","description":"Blocked screen shows blocked message",
         "preconditions":"User with 'blocked' status",
         "steps":"1. Login with blocked account",
         "expected":"Screen shows 'Account blocked due to violation'",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-AS-04","description":"Contact Support button navigates to support",
         "preconditions":"Pending/rejected screen open",
         "steps":"1. Tap Contact Support",
         "expected":"Navigates to Support screen",
         "priority":"Medium","status":"Pass"},
        {"tc_id":"TC-AS-05","description":"Logout from status screen works",
         "preconditions":"Pending/rejected screen open",
         "steps":"1. Tap Logout",
         "expected":"Signed out; returns to User Choice screen",
         "priority":"High","status":"Pass"},
    ]))
    elems.append(Spacer(1, 0.5*cm))

    # ── 20. Admin Login ───────────────────────────────────────────────────────
    elems += [section_header("20. Admin – Login & Dashboard"), Spacer(1, 0.3*cm)]
    elems.append(tc_table([
        {"tc_id":"TC-AL-01","description":"Empty username shows validation error",
         "preconditions":"Admin Login screen open",
         "steps":"1. Leave username empty\n2. Tap Login",
         "expected":"Validation error: username required",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-AL-02","description":"Empty password shows validation error",
         "preconditions":"Admin Login screen open",
         "steps":"1. Enter username\n2. Leave password empty\n3. Tap Login",
         "expected":"Validation error: password required",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-AL-03","description":"Wrong credentials show error",
         "preconditions":"Admin Login screen open",
         "steps":"1. Enter wrong credentials\n2. Tap Login",
         "expected":"Error message displayed",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-AL-04","description":"Correct credentials navigate to Dashboard",
         "preconditions":"Valid admin credentials",
         "steps":"1. Enter correct admin username and password\n2. Tap Login",
         "expected":"Navigates to Admin Dashboard screen",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-AL-05","description":"Admin Dashboard shows stat cards",
         "preconditions":"Admin logged in",
         "steps":"1. Observe dashboard",
         "expected":"Total Users, Active Rides, Pending Verifications cards visible",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-AL-06","description":"Search bar filters users",
         "preconditions":"Admin Dashboard open",
         "steps":"1. Type name in search bar",
         "expected":"User list filtered by search query",
         "priority":"Medium","status":"Pass"},
        {"tc_id":"TC-AL-07","description":"Admin bottom nav links work",
         "preconditions":"Admin Dashboard open",
         "steps":"1. Tap Drivers / Riders / Rides in bottom nav",
         "expected":"Navigates to respective list screens",
         "priority":"High","status":"Pass"},
    ]))
    elems.append(Spacer(1, 0.5*cm))

    # ── 21. Admin Driver Management ───────────────────────────────────────────
    elems += [section_header("21. Admin – Driver Management"), Spacer(1, 0.3*cm)]
    elems.append(tc_table([
        {"tc_id":"TC-AD-01","description":"Drivers list loads all drivers",
         "preconditions":"Admin on Drivers List screen",
         "steps":"1. Navigate to Drivers List",
         "expected":"All drivers displayed with name and status badge",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-AD-02","description":"Pending tab filters pending drivers",
         "preconditions":"Drivers List screen open",
         "steps":"1. Tap 'Pending' tab",
         "expected":"Only pending drivers shown",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-AD-03","description":"Approved tab filters approved drivers",
         "preconditions":"Drivers List screen open",
         "steps":"1. Tap 'Approved' tab",
         "expected":"Only approved drivers shown",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-AD-04","description":"Search filters drivers by name",
         "preconditions":"Drivers List screen open",
         "steps":"1. Type driver name in search",
         "expected":"List filtered to matching drivers",
         "priority":"Medium","status":"Pass"},
        {"tc_id":"TC-AD-05","description":"Tapping driver opens Driver Details screen",
         "preconditions":"Drivers List screen open",
         "steps":"1. Tap on a driver",
         "expected":"Driver Details screen opens with all documents",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-AD-06","description":"Approve driver updates status in Firestore",
         "preconditions":"Driver Details screen open",
         "steps":"1. Tap Approve button",
         "expected":"Driver status updated to 'approved'; navigates back",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-AD-07","description":"Reject driver updates status in Firestore",
         "preconditions":"Driver Details screen open",
         "steps":"1. Tap Reject button",
         "expected":"Driver status updated to 'rejected'; navigates back",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-AD-08","description":"Block driver updates status in Firestore",
         "preconditions":"Driver Details screen open",
         "steps":"1. Tap Block button",
         "expected":"Driver isBlocked = true; status updated in Firestore",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-AD-09","description":"Driver documents visible (license, CNIC, selfie, vehicle)",
         "preconditions":"Driver Details screen open",
         "steps":"1. Scroll through Driver Details screen",
         "expected":"All documents and photos rendered correctly",
         "priority":"High","status":"Pass"},
    ]))
    elems.append(Spacer(1, 0.5*cm))

    # ── 22. Admin Rider Management ────────────────────────────────────────────
    elems += [section_header("22. Admin – Rider Management"), Spacer(1, 0.3*cm)]
    elems.append(tc_table([
        {"tc_id":"TC-AR-01","description":"Riders list loads all passengers",
         "preconditions":"Admin on Riders List screen",
         "steps":"1. Navigate to Riders List",
         "expected":"All passengers displayed with name and status",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-AR-02","description":"Tab filters work (Pending, Approved, Rejected, Blocked)",
         "preconditions":"Riders List screen open",
         "steps":"1. Tap each status tab",
         "expected":"List filtered per selected status",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-AR-03","description":"Tapping rider opens Rider Verification screen",
         "preconditions":"Riders List screen open",
         "steps":"1. Tap on a rider",
         "expected":"Rider Verification screen with CNIC and selfie images",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-AR-04","description":"Approve rider updates Firestore status",
         "preconditions":"Rider Verification screen open",
         "steps":"1. Tap Approve",
         "expected":"Status = 'approved'; navigates back",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-AR-05","description":"Reject rider updates Firestore status",
         "preconditions":"Rider Verification screen open",
         "steps":"1. Tap Reject",
         "expected":"Status = 'rejected'; navigates back",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-AR-06","description":"Block rider sets isBlocked in Firestore",
         "preconditions":"Rider Verification screen open",
         "steps":"1. Tap Block",
         "expected":"isBlocked = true in Firestore; status updated",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-AR-07","description":"Search filters riders by name",
         "preconditions":"Riders List screen open",
         "steps":"1. Type rider name in search",
         "expected":"List filtered to matching riders",
         "priority":"Medium","status":"Pass"},
    ]))
    elems.append(Spacer(1, 0.5*cm))

    # ── 23. Terms & Privacy ───────────────────────────────────────────────────
    elems += [section_header("23. Terms & Conditions / Privacy Policy"), Spacer(1, 0.3*cm)]
    elems.append(tc_table([
        {"tc_id":"TC-TC-01","description":"Terms screen loads all sections",
         "preconditions":"Navigate to Terms & Conditions",
         "steps":"1. Open Terms & Conditions screen\n2. Scroll through content",
         "expected":"All sections visible: Introduction, User Accounts, Safety, Privacy, Payments, Contact",
         "priority":"Medium","status":"Pass"},
        {"tc_id":"TC-TC-02","description":"Content is scrollable",
         "preconditions":"Terms screen open",
         "steps":"1. Scroll through the content",
         "expected":"Entire document can be scrolled without UI issues",
         "priority":"Low","status":"Pass"},
        {"tc_id":"TC-TC-03","description":"Back button returns to previous screen",
         "preconditions":"Terms screen open",
         "steps":"1. Tap back button",
         "expected":"Returns to previous screen without errors",
         "priority":"Medium","status":"Pass"},
        {"tc_id":"TC-TC-04","description":"Privacy Policy screen loads content",
         "preconditions":"Navigate to Privacy & Security screen",
         "steps":"1. Open Privacy screen",
         "expected":"Privacy policy content displayed and scrollable",
         "priority":"Medium","status":"Pass"},
    ]))
    elems.append(Spacer(1, 0.5*cm))

    # ── 24. Edge Cases ────────────────────────────────────────────────────────
    elems += [section_header("24. Edge Cases & Error Handling"), Spacer(1, 0.3*cm)]
    elems.append(tc_table([
        {"tc_id":"TC-EC-01","description":"No internet connection shows appropriate error",
         "preconditions":"Device with no internet",
         "steps":"1. Disable internet\n2. Attempt login",
         "expected":"Error message: no internet connection or network error",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-EC-02","description":"Location permission denied handles gracefully",
         "preconditions":"Location permission denied",
         "steps":"1. Deny location permission\n2. Open dashboard",
         "expected":"App requests permission or shows message; does not crash",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-EC-03","description":"Camera permission denied falls back to gallery",
         "preconditions":"Camera permission denied",
         "steps":"1. Deny camera on Selfie screen",
         "expected":"Fallback to gallery option; no crash",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-EC-04","description":"Blurry CNIC image still shows fields for manual entry",
         "preconditions":"CNIC screen open",
         "steps":"1. Upload low-quality CNIC image",
         "expected":"OCR may fail; fields remain editable for manual input",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-EC-05","description":"Large image compressed before upload",
         "preconditions":"Vehicle Info or Selfie screen",
         "steps":"1. Upload a 10MB+ image",
         "expected":"Image compressed; no out-of-memory error; uploaded successfully",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-EC-06","description":"Firebase auth session persists on app restart",
         "preconditions":"User logged in previously",
         "steps":"1. Close and reopen app",
         "expected":"User remains logged in; navigates directly to dashboard",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-EC-07","description":"Multiple rapid taps on login button does not duplicate requests",
         "preconditions":"Login screen open",
         "steps":"1. Rapidly tap login button multiple times",
         "expected":"Only one login request sent; button disabled during loading",
         "priority":"Medium","status":"Pass"},
        {"tc_id":"TC-EC-08","description":"OTP field accepts only 6 digits",
         "preconditions":"OTP field visible on Phone Login",
         "steps":"1. Enter more than 6 digits in OTP field",
         "expected":"Input limited to 6 digits",
         "priority":"Medium","status":"Pass"},
        {"tc_id":"TC-EC-09","description":"Ride booking with no destination shows error",
         "preconditions":"Passenger Dashboard open",
         "steps":"1. Tap 'Find Ride' without entering destination",
         "expected":"Validation error: destination required",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-EC-10","description":"Driver cannot book a ride as passenger",
         "preconditions":"Driver account logged in",
         "steps":"1. Login as driver\n2. Attempt to access Passenger Dashboard flow",
         "expected":"Role-based routing ensures driver sees Driver Dashboard only",
         "priority":"High","status":"Pass"},
        {"tc_id":"TC-EC-11","description":"App handles Firestore document not found gracefully",
         "preconditions":"User document deleted from Firestore",
         "steps":"1. Delete user doc in Firestore\n2. Login",
         "expected":"App handles null data gracefully; no crash",
         "priority":"Medium","status":"Pass"},
        {"tc_id":"TC-EC-12","description":"Special characters in name field handled",
         "preconditions":"Signup or Edit Profile screen",
         "steps":"1. Enter name with special chars: 'Ayesha & Ali!'",
         "expected":"Name saved correctly; no UI breakage",
         "priority":"Low","status":"Pass"},
    ]))
    elems.append(Spacer(1, 1*cm))

    return elems


# ── Build ─────────────────────────────────────────────────────────────────────

story = []
story += cover()
story += toc()
story += all_sections()

build_pdf(story)

from fpdf import FPDF

class ResumePDF(FPDF):
    def header(self):
        # Add a subtle header line
        self.set_draw_color(70, 130, 180)
        self.set_line_width(0.5)
        self.line(10, 10, 200, 10)
    
    def section_title(self, title):
        self.set_font("Arial", 'B', 11)
        self.set_text_color(70, 130, 180)
        self.cell(0, 6, title, ln=True)
        self.set_draw_color(70, 130, 180)
        self.set_line_width(0.3)
        self.line(10, self.get_y(), 200, self.get_y())
        self.ln(2)
        self.set_text_color(0, 0, 0)
    
    def section_content(self, text, indent=0):
        self.set_font("Arial", '', 9)
        self.set_x(10 + indent)
        self.multi_cell(180 - indent, 4, text)
        self.ln(1)

# Create PDF
pdf = ResumePDF()
pdf.add_page()
pdf.set_auto_page_break(auto=True, margin=10)
pdf.set_margins(10, 10, 10)

# Name Header
pdf.set_font("Arial", 'B', 18)
pdf.set_text_color(70, 130, 180)
pdf.cell(0, 8, "PRINCESS BONEO BINAS", ln=True, align="C")

# Contact Information - Centered
pdf.set_font("Arial", '', 9)
pdf.set_text_color(80, 80, 80)
pdf.cell(0, 4, "Phone: 09917064023 / 09682981988", ln=True, align="C")
pdf.cell(0, 4, "Email: princess.binasb@gmail.com", ln=True, align="C")
pdf.cell(0, 4, "Address: Dream Homes Blk 3 Lot 5 Tejero", ln=True, align="C")
pdf.ln(3)
pdf.set_text_color(0, 0, 0)

# Objective
pdf.section_title("OBJECTIVE")
pdf.section_content(
    "To apply my knowledge, skills, and techniques learned from my professional experience "
    "to contribute to the continuous growth of the company, while seeking opportunities for "
    "personal and career development."
)

# Personal Information
pdf.section_title("PERSONAL INFORMATION")
pdf.set_font("Arial", '', 10)
personal_data = [
    ("Date of Birth:", "July 23, 1994"),
    ("Place of Birth:", "Caloocan City"),
    ("Age:", "31 years old"),
    ("Gender:", "Female"),
    ("Citizenship:", "Filipino"),
    ("Civil Status:", "Single"),
    ("Religion:", "Roman Catholic"),
    ("Height:", "5'1\""),
    ("Weight:", "45 kg"),
    ("Languages:", "Tagalog & English")
]
for label, value in personal_data:
    pdf.set_font("Arial", 'B', 10)
    pdf.cell(40, 6, label, 0, 0)
    pdf.set_font("Arial", '', 10)
    pdf.cell(0, 6, value, 0, 1)
pdf.ln(2)

# Skills
pdf.section_title("CORE COMPETENCIES")
skills = [
    "Hardworking and quick learner with strong adaptability",
    "Responsible, efficient, and flexible in various work environments",
    "Self-motivated with excellent listening skills",
    "Strong organizational and time management abilities",
    "Customer service oriented with attention to detail"
]
pdf.set_font("Arial", '', 9)
for skill in skills:
    pdf.ln(1)
    pdf.cell(0, 4, skill, 0, 1)
pdf.ln(1)

# Work Experience
pdf.section_title("PROFESSIONAL EXPERIENCE")
experiences = [
    ("SCAD Services Co.", "Production Operator", "Peza Rosario, Cavite", "April 2024"),
    ("Island Cove POGO", "Service Crew / Housekeeping", "Kawit, Cavite", ""),
    ("House Technology Industries Pte. Ltd.", "Production Operator", "General Trias, Cavite", ""),
    ("Divi Mall Pricing", "Clerk Office", "Imus Anabu", ""),
    ("Divi Mart Mall", "Cashier", "GenTri Manggahan", ""),
    ("167 Hypermart", "Cashier", "Tanauan, Batangas", ""),
    ("167 Hypermart", "Saleslady", "Montalban, Rizal", ""),
    ("Sea Food Restaurant", "Waitress", "Montalban, Rizal", "")
]

for company, position, location, period in experiences:
    pdf.set_font("Arial", 'B', 9)
    pdf.cell(0, 4, position, ln=True)
    pdf.set_font("Arial", 'I', 8)
    pdf.set_text_color(80, 80, 80)
    if period:
        pdf.cell(0, 3, f"{company} | {location} | {period}", ln=True)
    else:
        pdf.cell(0, 3, f"{company} | {location}", ln=True)
    pdf.set_text_color(0, 0, 0)
    pdf.ln(1)
pdf.ln(1)

# Educational Background
pdf.section_title("EDUCATIONAL BACKGROUND")
pdf.set_font("Arial", 'B', 9)
pdf.cell(0, 4, "Secondary Education", ln=True)
pdf.set_font("Arial", '', 9)
pdf.cell(0, 3, "San Isidro National High School, Montalban, Rizal", ln=True)
pdf.set_font("Arial", 'I', 8)
pdf.set_text_color(80, 80, 80)
pdf.cell(0, 3, "2009 - 2013", ln=True)
pdf.ln(1)
pdf.set_text_color(0, 0, 0)

pdf.set_font("Arial", 'B', 9)
pdf.cell(0, 4, "Primary Education", ln=True)
pdf.set_font("Arial", '', 9)
pdf.cell(0, 3, "San Isidro West Elementary School, Albay", ln=True)
pdf.set_font("Arial", 'I', 8)
pdf.set_text_color(80, 80, 80)
pdf.cell(0, 3, "2008 - 2009", ln=True)
pdf.ln(2)
pdf.set_text_color(0, 0, 0)

# Certification Statement
pdf.ln(2)
pdf.set_font("Arial", 'I', 8)
pdf.set_text_color(80, 80, 80)
pdf.multi_cell(0, 3, 
    "I hereby certify that all the above information is true and correct to the best of my knowledge and belief.")
pdf.ln(3)

pdf.set_font("Arial", 'B', 9)
pdf.set_text_color(0, 0, 0)
pdf.cell(0, 3, "PRINCESS BONEO BINAS", ln=True)
pdf.set_draw_color(0, 0, 0)
pdf.line(10, pdf.get_y(), 70, pdf.get_y())
pdf.set_font("Arial", '', 8)
pdf.set_text_color(80, 80, 80)
pdf.cell(0, 3, "Applicant's Signature", ln=True)

# Save PDF
pdf.output("PRINCESS_BONEO_BINAS_Professional_Resume.pdf")
print("Professional resume PDF generated successfully!")
print("File: PRINCESS_BONEO_BINAS_Professional_Resume.pdf")
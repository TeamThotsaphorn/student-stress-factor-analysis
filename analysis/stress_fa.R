# =============================================================================
# Factor Analysis of Psychological Stress among University Students
# Exploratory Factor Analysis (PCA extraction + Varimax) and group comparisons
# Data: Hussen, F. M., Ibrahim, H. M., & Nafea, A. A. (2026). Student Psychological Stress
#       Survey Dataset (University of Anbar, Iraq) (Version 2). Mendeley Data.
#       https://doi.org/10.17632/428whwsk6c.2  (CC BY 4.0) | n = 610, 15 items
# Step 1: run notebooks/01_data_preparation.ipynb (creates data/processed/stress_clean.csv)
# Step 2: run from the repository root:  source("analysis/stress_fa.R")
# =============================================================================

# การวิเคราะห์ปัจจัยความเครียดทางจิตใจในนักศึกษามหาวิทยาลัย
# ข้อมูล: data/processed/stress_clean.csv (สร้างจาก notebooks/01_data_preparation.ipynb) | n = 610, 15 ข้อ, 1-5
# ไฟล์ข้อมูลอยู่ในโฟลเดอร์ data/ ให้รันสคริปต์จากโฟลเดอร์หลักของโปรเจกต์
# ขั้นตอนและคำสั่งตามเอกสารบทที่ 6 การวิเคราะห์ปัจจัย
# install.packages(c("psych", "Hmisc", "GGally", "REdaS", "ggplot2"))

library(psych)

# ---- 4.1 อ่านข้อมูลที่เตรียมแล้ว ----
# การเตรียมข้อมูลทำใน notebooks/01_data_preparation.ipynb (Python)
# แปลงคำตอบเป็น 1-5 ตรวจกับไฟล์ Encoded (ตรงกัน 9,150 ช่อง) และเพิ่มคอลัมน์ id แล้ว
df <- read.csv("data/processed/stress_clean.csv")
dim(df)                                   # 610 x 20
stopifnot(nrow(df) == 610, !anyNA(df))    # หยุดถ้าข้อมูลไม่ครบ (ให้รัน notebook ก่อน)
head(df)

# ข้อคำถาม 15 ข้อสำหรับวิเคราะห์ปัจจัย (ดึงจากตารางเดียวกัน)
stress <- df[, paste0("Q", 1:15)]

# ---- 4.2 สถิติพรรณนา ----
describe(stress)[, c("n", "median", "skew", "kurtosis")]
# ข้อมูลเรียงลำดับ: ร้อยละแต่ละระดับคำตอบ และร้อยละที่ตอบ 4-5 (บ่อย/เป็นประจำ)
round(t(sapply(stress, function(x) prop.table(table(factor(x, levels = 1:5))) * 100)), 1)
round(sapply(stress, function(x) mean(x >= 4) * 100), 1)

# ---- 4.2 เมทริกซ์สหสัมพันธ์ ----
library(Hmisc)
rcorr(as.matrix(stress))

library(GGally)
ggcorr(stress, method = c("pairwise", "pearson"),
       label = TRUE, label_alpha = TRUE, label_round = 2, name = expression(rho))

# ---- 4.3 ตรวจสอบข้อตกลงเบื้องต้น ----
library(REdaS)
bart_spher(stress)      # Bartlett's Test of Sphericity
KMO(stress)             # KMO รวม + MSA รายข้อ

# ---- 4.4 สกัดปัจจัย: วิธีส่วนประกอบหลัก ----
FA_PC <- principal(stress, nfactors = 15, rotate = "none")
FA_PC$values                                   # ค่าเฉพาะ
cumsum(FA_PC$values) / 15 * 100                # ร้อยละความแปรปรวนสะสม

eigen_values <- FA_PC$values
plot(1:15, eigen_values, pch = 20, type = "b", lwd = 2,
     main = "Scree Plot", xlab = "Factor", ylab = "Eigenvalues")
abline(h = mean(eigen_values), col = "red", lwd = 2)

# ---- 4.5 กำหนดจำนวนปัจจัย: ค่าเฉพาะ > 1 = 4 ปัจจัย ----

# ---- 4.6 ค่าถ่วงปัจจัยก่อนหมุนแกน ----
print(principal(stress, 4, rotate = "none")$loadings, cutoff = 0.5)

# ---- 4.7 หมุนแกนด้วย Varimax ----
FA_PC_Varimax <- principal(stress, nfactors = 4, rotate = "varimax", method = "regression")
print(FA_PC_Varimax$loadings, cutoff = 0.5, sort = TRUE)
FA_PC_Varimax$communality

# ---- 4.8 คะแนนปัจจัย ----
head(FA_PC_Varimax$scores, 15)

# ---- เปรียบเทียบคะแนนปัจจัยระหว่างกลุ่ม ----

# ตั้งชื่อคอลัมน์คะแนนปัจจัยตามข้อที่โหลดสูงสุด (กันปัญหา R เรียงลำดับ RC ต่างกัน)
L  <- unclass(FA_PC_Varimax$loadings)
sc <- data.frame(FA_PC_Varimax$scores)
pick <- function(q) which.max(abs(L[q, ]))
scores <- data.frame(exam_emotion = sc[, pick("Q6")],  social    = sc[, pick("Q12")],
                     academic     = sc[, pick("Q4")],  financial = sc[, pick("Q9")])
# เติมคะแนนปัจจัยเป็นคอลัมน์ใหม่ในตารางเดิม (stress มาจาก df แถวจึงตรงกันเสมอ)
d <- cbind(df, scores)
write.csv(d, "data/processed/stress_with_scores.csv", row.names = FALSE)

# เพศ (Welch t-test)
for (f in names(scores)) { cat("\n", f, "\n"); print(t.test(d[[f]] ~ d$gender)) }
# สถานภาพสมรส
for (f in names(scores)) { cat("\n", f, "\n"); print(t.test(d[[f]] ~ d$marital)) }

# ชั้นปี 1-4 (ตัด ป.โท 6 คน และ ป.เอก 1 คน เพราะกลุ่มเล็กเกินไป)
st <- subset(d, grepl("^Stage", stage))
for (f in names(scores)) {
  cat("\n=====", f, "=====\n")
  fit <- aov(st[[f]] ~ st$stage)
  print(summary(fit))
  print(TukeyHSD(fit))
  print(oneway.test(st[[f]] ~ st$stage, var.equal = FALSE))   # Welch ANOVA กรณีความแปรปรวนไม่เท่ากัน
}
aggregate(cbind(exam_emotion, social, academic, financial) ~ gender, data = d, FUN = mean)
aggregate(cbind(exam_emotion, social, academic, financial) ~ stage,  data = st, FUN = mean)

# =============================================================================
# ---- กราฟสำหรับ README (ggplot2) ----
# ใช้ผลจากด้านบน: FA_PC, L, pick(), scores, d
# บันทึกไฟล์: figures/scree_plot.png, figures/rotated_loadings.png,
#             figures/factor_scores_by_gender.png
# =============================================================================
library(ggplot2)
dir.create("figures", showWarnings = FALSE)

INK <- "#1D2B45"; ACCENT <- "#C8551F"; BLUE <- "#2E6DA4"

# ---- 1) Scree plot ----------------------------------------------------------
ev    <- FA_PC$values
scree <- data.frame(component = 1:15, eigenvalue = ev, keep = ev > 1)

p1 <- ggplot(scree, aes(component, eigenvalue)) +
  geom_hline(yintercept = 1, linetype = "dashed", colour = ACCENT) +
  geom_line(colour = INK, linewidth = 1) +
  geom_point(aes(colour = keep), size = 3) +
  geom_text(data = subset(scree, keep), aes(label = sprintf("%.2f", eigenvalue)),
            nudge_x = 0.4, nudge_y = 0.15, size = 3.2, colour = INK) +
  annotate("text", x = 15, y = 1.15, label = "eigenvalue = 1", hjust = 1, colour = ACCENT) +
  scale_colour_manual(values = c(`TRUE` = ACCENT, `FALSE` = INK), guide = "none") +
  scale_x_continuous(breaks = 1:15) +
  labs(title = sprintf("Scree plot: %d components with eigenvalue > 1 (%.1f%% of variance)",
                       sum(ev > 1), sum(ev[ev > 1]) / 15 * 100),
       x = "Component", y = "Eigenvalue") +
  theme_minimal(base_size = 12) +
  theme(panel.grid.minor = element_blank(), panel.grid.major.x = element_blank())

ggsave("figures/scree_plot.png", p1, width = 8, height = 4.5, dpi = 150, bg = "white")

# ---- 2) Rotated loadings heatmap ---------------------------------------------
# ใช้ L และ pick() จากส่วนเปรียบเทียบกลุ่ม เรียงคอลัมน์ตามข้อที่เป็นตัวแทนของแต่ละปัจจัย
idx <- c(pick("Q6"), pick("Q12"), pick("Q4"), pick("Q9"))
factor_names <- c("Exam & emotion", "Social", "Academic", "Financial")
Lr <- L[, idx]
colnames(Lr) <- factor_names

item_labels <- c("Q1 Exam anxiety", "Q2 Sleep problems (exams)", "Q3 Poor concentration",
                 "Q4 Easily distracted", "Q5 Irritability", "Q6 Mood changes (exams)",
                 "Q7 Course too difficult", "Q8 Overwhelmed by workload",
                 "Q9 Tuition/living costs", "Q10 Money affects study", "Q11 Lonely",
                 "Q12 Hard to make friends", "Q13 Stress with instructors",
                 "Q14 Sad / unmotivated", "Q15 Sleepless over university")

# sort items: by the factor they load on most, then by loading size
grp <- apply(Lr, 1, which.max)
top <- apply(Lr, 1, max)
ord <- order(grp, -top)

heat <- data.frame(item    = rep(rownames(Lr), times = 4),
                   factor  = rep(colnames(Lr), each = 15),
                   loading = as.vector(Lr))
heat$label  <- factor(item_labels[match(heat$item, paste0("Q", 1:15))],
                      levels = rev(item_labels[ord]))
heat$factor <- factor(heat$factor, levels = factor_names)
heat$main   <- heat$loading == top[heat$item]

p2 <- ggplot(heat, aes(factor, label, fill = loading)) +
  geom_tile(colour = "white") +
  geom_text(aes(label = sprintf("%.2f", loading), colour = loading > 0.55,
                fontface = ifelse(main, "bold", "plain")), size = 3.2) +
  scale_fill_gradient(low = "#F3F7FB", high = "#08519C", limits = c(-0.1, 1)) +
  scale_colour_manual(values = c(`TRUE` = "white", `FALSE` = INK), guide = "none") +
  labs(title = "Varimax-rotated loadings", x = NULL, y = NULL, fill = "Loading") +
  theme_minimal(base_size = 11) +
  theme(panel.grid = element_blank())

ggsave("figures/rotated_loadings.png", p2, width = 7.5, height = 7, dpi = 150, bg = "white")

# ---- 3) Mean factor scores by gender -----------------------------------------
# ใช้ scores และ d จากส่วนเปรียบเทียบกลุ่ม (เรียงคอลัมน์ตรงกับ factor_names แล้ว)
means <- aggregate(scores, by = list(gender = d$gender), FUN = mean)
long  <- data.frame(gender = rep(means$gender, times = 4),
                    factor = factor(rep(factor_names, each = nrow(means)), levels = factor_names),
                    mean   = as.vector(as.matrix(means[, -1])))

p_exam <- t.test(d$exam_emotion ~ d$gender)$p.value   # Welch t-test ด้านการสอบและอารมณ์

p3 <- ggplot(long, aes(factor, mean, fill = gender)) +
  geom_col(position = position_dodge(0.75), width = 0.7) +
  geom_hline(yintercept = 0, colour = "grey40") +
  geom_text(aes(label = sprintf("%+.2f", mean), vjust = ifelse(mean >= 0, -0.4, 1.3)),
            position = position_dodge(0.75), size = 3.2, colour = INK) +
  scale_fill_manual(values = c(Female = ACCENT, Male = BLUE)) +
  scale_y_continuous(expand = expansion(mult = 0.15)) +
  labs(title = sprintf("Mean factor scores by gender (exam & emotion: p %s)",
                       format.pval(p_exam, eps = 0.001)),
       x = NULL, y = "Mean factor score (z)", fill = NULL) +
  theme_minimal(base_size = 12) +
  theme(panel.grid.minor = element_blank(), panel.grid.major.x = element_blank(),
        legend.position = "top")

ggsave("figures/factor_scores_by_gender.png", p3, width = 8, height = 4.5, dpi = 150, bg = "white")

# หมายเหตุ: R อาจเรียงลำดับปัจจัย (RC1-RC4) หรือใส่เครื่องหมายต่างจากผลเบื้องต้น
# ให้ดูว่าข้อใดมีค่าถ่วงสูงในแต่ละปัจจัย
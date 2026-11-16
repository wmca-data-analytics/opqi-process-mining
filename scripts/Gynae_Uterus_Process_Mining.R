### Gynaecological - Uterus - Process Mining ###################################

# Data are from a patient level download of CWT data. File from https://nwwcancerwaitingtimes.sdcs.digital.nhs.uk/ 
# Selected for tumour type = Gynaecological - Uterus
# Events to filter by = Treatment Start Date (Cancer) - Treatment Provider Search
# Dates to download = 01-08-2025 to 31-07-2026
# Snapshot = Final
# Records to include = Only include records submitted by the submission deadline
# Report Type = ICS Sub Location Report Download (enabling a view of commissioned patients transferring in and out of the West Midlands)

# Install packages if required #################################################
# install.packages("tidyverse")
# install.packages("lubridate")
# install.packages("bupaR")
# install.packages("edeaR")
# install.packages("eventdataR")
# install.packages("processcheckR")
# install.packages("processmapR")

# Load the libraries ###########################################################
library(tidyverse)
library(lubridate)
library(bupaR)
library(edeaR)
library(eventdataR)
library(processcheckR)
library(processmapR)

# Read in files ################################################################
setwd("~/GitHub/Process%20Mining")

# Read in downloaded file from https://nwwcancerwaitingtimes.sdcs.digital.nhs.uk/ 
data <- read.csv("data/01 AUG 2025 TO 31  JUL 2026 E56000007-E56000031 CCG RECORDS (1).csv")

# Only include West Midlands Sub ICB Locations
data <- data |> 
  filter(ICSSubLocationRelatedOrganisationTsdCode %in% c("05W", "05Q", "D2P2L", "B2M3M", "05D", "18C", "15E", "M2L0M", "05G", "05V", "04Y"))

# Read in a mapping file of site codes and trust and site names
site_codes <- read.csv("lookups/WMCA_Site_Code_Mapping.csv")

################################################################################
# Filter for first definitive treatments and FDS End Date present ############## 
# This removes patients with an FDS outside of the timeframe for data extraction and removes subsequent treatments.
# Apply relevant FDS, 31 and 62 day rules for patient inclusion 

# For reference: CancerTreatmentEventType
# 01 First Definitive Treatment for a new Primary Cancer
# 02 Second or subsequent treatment for a new Primary Cancer
# 03 Treatment for a local recurrence of a Primary Cancer
# 04 Treatment for a regional Recurrence of Cancer
# 05 Treatment for a distant Recurrence of Cancer (metastatic disease)
# 06 Treatment for multiple Recurrence of Cancer (local and/or regional and/or distant)
# 07 First treatment for metastatic disease following an unknown Primary Cancer
# 08 Second or subsequent treatment for metastatic disease following an unknown Primary Cancer
# 09 Treatment for relapse of Primary Cancer (second or subsequent)
# 10 Treatment for progression of Primary Cancer (second or subsequent)
# 10 Treatment for Cancer Progression of Primary Cancer (second or subsequent)
# 11 Treatment for Cancer Transformation of Primary Cancer (second or subsequent)
# 12 First treatment for metastatic disease following a known Primary Cancer

# Patients to be included using [Report 19.1- 28 Day General FDS](https://digital.nhs.uk/data-and-information/data-collections-and-data-sets/data-collections/cancerwaitingtimescwt/report-guidance)
data_process <- data %>%
  filter(
    (PriorityTypeCode == 3 & !SourceOfReferralForOutPatients == 17) |
      (PriorityTypeCode == 2 & SourceOfReferralForOutPatients == 17), # from screening
    (CancerFasterDiagnosisPathwayEndReason %in% c("1", "2", "4") |
       CancerFasterDiagnosisPathwayEndReason == 3 & CancerFasterDiagnosisPathwayExclusionReason == 1), # Not used in this line & NumberOfDays_FDS > 28, unsure if this is relevant for patient journey
    !is.na(CancerFasterDiagnosisPathwayEndDate), !CancerFasterDiagnosisPathwayEndDate == "",
    !is.na(CancerReferralToTreatmentPeriodStartDate), !CancerReferralToTreatmentPeriodStartDate == ""
  )

# Patients to be included using [Report 25.1 - 31 Day General Treatment Standard (Tumour) Report](https://digital.nhs.uk/data-and-information/data-collections-and-data-sets/data-collections/cancerwaitingtimescwt/report-guidance)
# First treatment criteria are applied to show initial patient journey and not subsequent treatments.
data_process <- data_process |> 
  filter(CancerTreatmentEventType %in% c("1","7","12"), # ensures pathway shows first treatments only
         !is.na(PrimaryDiagnosisIcd), !PrimaryDiagnosisIcd == "",
         !is.na(CancerTreatmentPeriodStartDate), !CancerTreatmentPeriodStartDate == "",
         !is.na(TreatmentStartDateCancer), !TreatmentStartDateCancer == "")

# Patients to be included using [Report 26.1 - 62 Day General Standard (Tumour) Report](https://digital.nhs.uk/data-and-information/data-collections-and-data-sets/data-collections/cancerwaitingtimescwt/report-guidance)
# Criteria already applied in the above FDS and 31 day but included here for reference
data_process <- data_process %>%
  filter(
    (PriorityTypeCode == 3 & !SourceOfReferralForOutPatients == 17  & (!is.na(CancerTreatmentPeriodStartDate) & !CancerTreatmentPeriodStartDate == "") & (is.na(ConsultantUpgradeDate) | ConsultantUpgradeDate == "")) |
      (PriorityTypeCode == 2 & SourceOfReferralForOutPatients == 17 & (!is.na(CancerTreatmentPeriodStartDate) & !CancerTreatmentPeriodStartDate == "")) | # from screening
      (PriorityTypeCode == 2 & !SourceOfReferralForOutPatients == 17 & !is.na(ConsultantUpgradeDate) & !ConsultantUpgradeDate == "") # ensures consultant upgrades are present for 62 day
  )

# Select relevant columns to describe events on the pathway ####################
data_process <- data_process |> 
  select(CwtPatientRecordId, CancerReferralToTreatmentPeriodStartDate, OrganisationIdentifierPatientPathwayIdentifierIssuer, 
         ConsultantUpgradeDate, OrganisationSiteIdentifierOfProviderConsultantUpgrade,
         DateFirstSeen, OrganisationSiteIdentifierOfProviderFirstSeen,
         CancerFasterDiagnosisPathwayEndDate, PrimaryDiagnosisIcd, CancerFasterDiagnosisPathwayEndReason, PrimaryCancerSiteCancerFasterDiagnosisPathway, OrganisationSiteIdentifierOfCancerFasterDiagnosisEnd,
         
         ServiceRequestedDateInterProviderTransfer1, OrganisationIdentifierReferring1,
         ReferralRequestReceivedDateInterProviderTransfer1, OrganisationIdentifierReceiving1,
         
         ServiceRequestedDateInterProviderTransfer2, OrganisationIdentifierReferring2,
         ReferralRequestReceivedDateInterProviderTransfer2, OrganisationIdentifierReceiving2,
         
         ServiceRequestedDateInterProviderTransfer3, OrganisationIdentifierReferring3,
         ReferralRequestReceivedDateInterProviderTransfer3, OrganisationIdentifierReceiving3,
         
         ServiceRequestedDateInterProviderTransfer4, OrganisationIdentifierReferring4,
         ReferralRequestReceivedDateInterProviderTransfer4, OrganisationIdentifierReceiving4,
         
         ServiceRequestedDateInterProviderTransfer5, OrganisationIdentifierReferring5,
         ReferralRequestReceivedDateInterProviderTransfer5, OrganisationIdentifierReceiving5,
         
         ServiceRequestedDateInterProviderTransfer6, OrganisationIdentifierReferring6,
         ReferralRequestReceivedDateInterProviderTransfer6, OrganisationIdentifierReceiving6,
         
         ServiceRequestedDateInterProviderTransfer7, OrganisationIdentifierReferring7,
         ReferralRequestReceivedDateInterProviderTransfer7, OrganisationIdentifierReceiving7,
         
         ServiceRequestedDateInterProviderTransfer8, OrganisationIdentifierReferring8,
         ReferralRequestReceivedDateInterProviderTransfer8, OrganisationIdentifierReceiving8,
         
         ServiceRequestedDateInterProviderTransfer9, OrganisationIdentifierReferring9,
         ReferralRequestReceivedDateInterProviderTransfer9, OrganisationIdentifierReceiving9,
         
         ServiceRequestedDateInterProviderTransfer10, OrganisationIdentifierReferring10,
         ReferralRequestReceivedDateInterProviderTransfer10, OrganisationIdentifierReceiving10,
         
         CancerTreatmentPeriodStartDate, OrganisationSiteIdentifierOfProviderCancerDecisionToTreat, 
         TreatmentStartDateCancer, CancerTreatmentModality, OrganisationSiteIdentifierOfProviderCancerTreatmentStartDate)

# Remove duplicates through selecting the earliest treatment date (some patients are coded as having multiple first treatments)
data_process <- data_process |> 
  dplyr::group_by(CwtPatientRecordId) |> 
  arrange(TreatmentStartDateCancer) |> 
  slice(1L)

data_process <- data_process |> 
  dplyr::ungroup()

# Put "none" if an org code is missing to enable the milestones to be filtered out before visualisation. This distinguishes missing org codes from org codes that are present but mapped incorrectly to the mapping file.
data_process <- data_process |> 
  mutate(OrganisationIdentifierPatientPathwayIdentifierIssuer = ifelse(OrganisationIdentifierPatientPathwayIdentifierIssuer =="", "none", OrganisationIdentifierPatientPathwayIdentifierIssuer),
         OrganisationSiteIdentifierOfProviderConsultantUpgrade = ifelse(OrganisationSiteIdentifierOfProviderConsultantUpgrade =="", "none", OrganisationSiteIdentifierOfProviderConsultantUpgrade),
         OrganisationSiteIdentifierOfProviderFirstSeen = ifelse(OrganisationSiteIdentifierOfProviderFirstSeen =="", "none", OrganisationSiteIdentifierOfProviderFirstSeen),
         OrganisationSiteIdentifierOfCancerFasterDiagnosisEnd = ifelse(OrganisationSiteIdentifierOfCancerFasterDiagnosisEnd =="", "none", OrganisationSiteIdentifierOfCancerFasterDiagnosisEnd),
         
         OrganisationIdentifierReferring1 = ifelse(OrganisationIdentifierReferring1 ==""|is.na(OrganisationIdentifierReferring1), "none", OrganisationIdentifierReferring1),
         OrganisationIdentifierReceiving1 = ifelse(OrganisationIdentifierReceiving1 ==""|is.na(OrganisationIdentifierReceiving1), "none", OrganisationIdentifierReceiving1),
         
         OrganisationIdentifierReferring2 = ifelse(OrganisationIdentifierReferring2 ==""|is.na(OrganisationIdentifierReferring2), "none", OrganisationIdentifierReferring2),
         OrganisationIdentifierReceiving2 = ifelse(OrganisationIdentifierReceiving2 ==""|is.na(OrganisationIdentifierReceiving2), "none", OrganisationIdentifierReceiving2),
         
         OrganisationIdentifierReferring3 = ifelse(OrganisationIdentifierReferring3 ==""|is.na(OrganisationIdentifierReferring3), "none", OrganisationIdentifierReferring3),
         OrganisationIdentifierReceiving3 = ifelse(OrganisationIdentifierReceiving3 ==""|is.na(OrganisationIdentifierReceiving3), "none", OrganisationIdentifierReceiving3),
         
         OrganisationIdentifierReferring4 = ifelse(OrganisationIdentifierReferring4 ==""|is.na(OrganisationIdentifierReferring4), "none", OrganisationIdentifierReferring4),
         OrganisationIdentifierReceiving4 = ifelse(OrganisationIdentifierReceiving4 ==""|is.na(OrganisationIdentifierReceiving4), "none", OrganisationIdentifierReceiving4),
         
         OrganisationIdentifierReferring5 = ifelse(OrganisationIdentifierReferring5 ==""|is.na(OrganisationIdentifierReferring5), "none", OrganisationIdentifierReferring5),
         OrganisationIdentifierReceiving5 = ifelse(OrganisationIdentifierReceiving5 ==""|is.na(OrganisationIdentifierReceiving5), "none", OrganisationIdentifierReceiving5),
         
         OrganisationIdentifierReferring6 = ifelse(OrganisationIdentifierReferring6 ==""|is.na(OrganisationIdentifierReferring6), "none", OrganisationIdentifierReferring6),
         OrganisationIdentifierReceiving6 = ifelse(OrganisationIdentifierReceiving6 ==""|is.na(OrganisationIdentifierReceiving6), "none", OrganisationIdentifierReceiving6),
         
         OrganisationIdentifierReferring7 = ifelse(OrganisationIdentifierReferring7 ==""|is.na(OrganisationIdentifierReferring7), "none", OrganisationIdentifierReferring7),
         OrganisationIdentifierReceiving7 = ifelse(OrganisationIdentifierReceiving7 ==""|is.na(OrganisationIdentifierReceiving7), "none", OrganisationIdentifierReceiving7),
         
         OrganisationIdentifierReferring8 = ifelse(OrganisationIdentifierReferring8 ==""|is.na(OrganisationIdentifierReferring8), "none", OrganisationIdentifierReferring8),
         OrganisationIdentifierReceiving8 = ifelse(OrganisationIdentifierReceiving8 ==""|is.na(OrganisationIdentifierReceiving8), "none", OrganisationIdentifierReceiving8),
         
         OrganisationIdentifierReferring9 = ifelse(OrganisationIdentifierReferring9 ==""|is.na(OrganisationIdentifierReferring9), "none", OrganisationIdentifierReferring9),
         OrganisationIdentifierReceiving9 = ifelse(OrganisationIdentifierReceiving9 ==""|is.na(OrganisationIdentifierReceiving9), "none", OrganisationIdentifierReceiving9),
         
         OrganisationIdentifierReferring10 = ifelse(OrganisationIdentifierReferring10 ==""|is.na(OrganisationIdentifierReferring10), "none", OrganisationIdentifierReferring10),
         OrganisationIdentifierReceiving10 = ifelse(OrganisationIdentifierReceiving10 ==""|is.na(OrganisationIdentifierReceiving10), "none", OrganisationIdentifierReceiving10),
         
         OrganisationSiteIdentifierOfProviderCancerDecisionToTreat = ifelse(OrganisationSiteIdentifierOfProviderCancerDecisionToTreat =="", "none", OrganisationSiteIdentifierOfProviderCancerDecisionToTreat),
         OrganisationSiteIdentifierOfProviderCancerTreatmentStartDate = ifelse(OrganisationSiteIdentifierOfProviderCancerTreatmentStartDate =="", "none", OrganisationSiteIdentifierOfProviderCancerTreatmentStartDate)
         )

# Find date range
max_treatment_date <- data_process |> 
  select(TreatmentStartDateCancer) |> 
  mutate(TreatmentStartDateCancer = as.Date(TreatmentStartDateCancer)) |> 
  summarise(max(TreatmentStartDateCancer))

min_treatment_date <- data_process |> 
  select(TreatmentStartDateCancer) |> 
  mutate(TreatmentStartDateCancer = as.Date(TreatmentStartDateCancer)) |> 
  summarise(min(TreatmentStartDateCancer))

# Add Trust Site names abbreviated #############################################
data_process <- merge(data_process, site_codes, by.x = "OrganisationIdentifierPatientPathwayIdentifierIssuer", by.y = "Provider.Code", all.x = TRUE)

data_process <- data_process |> 
  mutate(OrganisationIdentifierPatientPathwayIdentifierIssuer = Trust_Abbr)

data_process <- data_process |>
  select(-Trust, -Trust_Abbr)

#
data_process <- merge(data_process, site_codes, by.x = "OrganisationSiteIdentifierOfProviderConsultantUpgrade", by.y = "Provider.Code", all.x = TRUE)

data_process <- data_process |> 
  mutate(OrganisationSiteIdentifierOfProviderConsultantUpgrade = Trust_Abbr)

data_process <- data_process |>
  select(-Trust, -Trust_Abbr)

#
data_process <- merge(data_process, site_codes, by.x = "OrganisationSiteIdentifierOfProviderFirstSeen", by.y = "Provider.Code", all.x = TRUE)

data_process <- data_process |> 
  mutate(OrganisationSiteIdentifierOfProviderFirstSeen = Trust_Abbr)

data_process <- data_process |>
  select(-Trust, -Trust_Abbr)

#
data_process <- merge(data_process, site_codes, by.x = "OrganisationSiteIdentifierOfCancerFasterDiagnosisEnd", by.y = "Provider.Code", all.x = TRUE)

data_process <- data_process |> 
  mutate(OrganisationSiteIdentifierOfCancerFasterDiagnosisEnd = Trust_Abbr)

data_process <- data_process |>
  select(-Trust, -Trust_Abbr)

# Inter provider transfers ###
data_process <- merge(data_process, site_codes, by.x = "OrganisationIdentifierReferring1", by.y = "Provider.Code", all.x = TRUE)

data_process <- data_process |> 
  mutate(OrganisationIdentifierReferring1 = Trust_Abbr)

data_process <- data_process |>
  select(-Trust, -Trust_Abbr)

# 
data_process <- merge(data_process, site_codes, by.x = "OrganisationIdentifierReceiving1", by.y = "Provider.Code", all.x = TRUE)

data_process <- data_process |> 
  mutate(OrganisationIdentifierReceiving1 = Trust_Abbr)

data_process <- data_process |>
  select(-Trust, -Trust_Abbr)

#
data_process <- merge(data_process, site_codes, by.x = "OrganisationIdentifierReferring2", by.y = "Provider.Code", all.x = TRUE)

data_process <- data_process |> 
  mutate(OrganisationIdentifierReferring2 = Trust_Abbr)

data_process <- data_process |>
  select(-Trust, -Trust_Abbr)

# 
data_process <- merge(data_process, site_codes, by.x = "OrganisationIdentifierReceiving2", by.y = "Provider.Code", all.x = TRUE)

data_process <- data_process |> 
  mutate(OrganisationIdentifierReceiving2 = Trust_Abbr)

data_process <- data_process |>
  select(-Trust, -Trust_Abbr)

#
data_process <- merge(data_process, site_codes, by.x = "OrganisationIdentifierReferring3", by.y = "Provider.Code", all.x = TRUE)

data_process <- data_process |> 
  mutate(OrganisationIdentifierReferring3 = Trust_Abbr)

data_process <- data_process |>
  select(-Trust, -Trust_Abbr)

# 
data_process <- merge(data_process, site_codes, by.x = "OrganisationIdentifierReceiving3", by.y = "Provider.Code", all.x = TRUE)

data_process <- data_process |> 
  mutate(OrganisationIdentifierReceiving3 = Trust_Abbr)

data_process <- data_process |>
  select(-Trust, -Trust_Abbr)

#
data_process <- merge(data_process, site_codes, by.x = "OrganisationIdentifierReferring4", by.y = "Provider.Code", all.x = TRUE)

data_process <- data_process |> 
  mutate(OrganisationIdentifierReferring4 = Trust_Abbr)

data_process <- data_process |>
  select(-Trust, -Trust_Abbr)

# 
data_process <- merge(data_process, site_codes, by.x = "OrganisationIdentifierReceiving4", by.y = "Provider.Code", all.x = TRUE)

data_process <- data_process |> 
  mutate(OrganisationIdentifierReceiving4 = Trust_Abbr)

data_process <- data_process |>
  select(-Trust, -Trust_Abbr)

#
data_process <- merge(data_process, site_codes, by.x = "OrganisationIdentifierReferring5", by.y = "Provider.Code", all.x = TRUE)

data_process <- data_process |> 
  mutate(OrganisationIdentifierReferring5 = Trust_Abbr)

data_process <- data_process |>
  select(-Trust, -Trust_Abbr)

# 
data_process <- merge(data_process, site_codes, by.x = "OrganisationIdentifierReceiving5", by.y = "Provider.Code", all.x = TRUE)

data_process <- data_process |> 
  mutate(OrganisationIdentifierReceiving5 = Trust_Abbr)

data_process <- data_process |>
  select(-Trust, -Trust_Abbr)

#
data_process <- merge(data_process, site_codes, by.x = "OrganisationIdentifierReferring6", by.y = "Provider.Code", all.x = TRUE)

data_process <- data_process |> 
  mutate(OrganisationIdentifierReferring6 = Trust_Abbr)

data_process <- data_process |>
  select(-Trust, -Trust_Abbr)

# 
data_process <- merge(data_process, site_codes, by.x = "OrganisationIdentifierReceiving6", by.y = "Provider.Code", all.x = TRUE)

data_process <- data_process |> 
  mutate(OrganisationIdentifierReceiving6 = Trust_Abbr)

data_process <- data_process |>
  select(-Trust, -Trust_Abbr)

#
data_process <- merge(data_process, site_codes, by.x = "OrganisationIdentifierReferring7", by.y = "Provider.Code", all.x = TRUE)

data_process <- data_process |> 
  mutate(OrganisationIdentifierReferring7 = Trust_Abbr)

data_process <- data_process |>
  select(-Trust, -Trust_Abbr)

# 
data_process <- merge(data_process, site_codes, by.x = "OrganisationIdentifierReceiving7", by.y = "Provider.Code", all.x = TRUE)

data_process <- data_process |> 
  mutate(OrganisationIdentifierReceiving7 = Trust_Abbr)

data_process <- data_process |>
  select(-Trust, -Trust_Abbr)

#
data_process <- merge(data_process, site_codes, by.x = "OrganisationIdentifierReferring8", by.y = "Provider.Code", all.x = TRUE)

data_process <- data_process |> 
  mutate(OrganisationIdentifierReferring8 = Trust_Abbr)

data_process <- data_process |>
  select(-Trust, -Trust_Abbr)

# 
data_process <- merge(data_process, site_codes, by.x = "OrganisationIdentifierReceiving8", by.y = "Provider.Code", all.x = TRUE)

data_process <- data_process |> 
  mutate(OrganisationIdentifierReceiving8 = Trust_Abbr)

data_process <- data_process |>
  select(-Trust, -Trust_Abbr)

#
data_process <- merge(data_process, site_codes, by.x = "OrganisationIdentifierReferring9", by.y = "Provider.Code", all.x = TRUE)

data_process <- data_process |> 
  mutate(OrganisationIdentifierReferring9 = Trust_Abbr)

data_process <- data_process |>
  select(-Trust, -Trust_Abbr)

# 
data_process <- merge(data_process, site_codes, by.x = "OrganisationIdentifierReceiving9", by.y = "Provider.Code", all.x = TRUE)

data_process <- data_process |> 
  mutate(OrganisationIdentifierReceiving9 = Trust_Abbr)

data_process <- data_process |>
  select(-Trust, -Trust_Abbr)

#
data_process <- merge(data_process, site_codes, by.x = "OrganisationIdentifierReferring10", by.y = "Provider.Code", all.x = TRUE)

data_process <- data_process |> 
  mutate(OrganisationIdentifierReferring10 = Trust_Abbr)

data_process <- data_process |>
  select(-Trust, -Trust_Abbr)

# 
data_process <- merge(data_process, site_codes, by.x = "OrganisationIdentifierReceiving10", by.y = "Provider.Code", all.x = TRUE)

data_process <- data_process |> 
  mutate(OrganisationIdentifierReceiving10 = Trust_Abbr)

data_process <- data_process |>
  select(-Trust, -Trust_Abbr)

#
data_process <- merge(data_process, site_codes, by.x = "OrganisationSiteIdentifierOfProviderCancerDecisionToTreat", by.y = "Provider.Code", all.x = TRUE)

data_process <- data_process |> 
  mutate(OrganisationSiteIdentifierOfProviderCancerDecisionToTreat = Trust_Abbr)

data_process <- data_process |>
  select(-Trust, -Trust_Abbr)

#
data_process <- merge(data_process, site_codes, by.x = "OrganisationSiteIdentifierOfProviderCancerTreatmentStartDate", by.y = "Provider.Code", all.x = TRUE)

data_process <- data_process |> 
  mutate(OrganisationSiteIdentifierOfProviderCancerTreatmentStartDate = Trust_Abbr)

data_process <- data_process |>
  select(-Trust, -Trust_Abbr)

##############################################################################################################################################
# Add CancerTreatmentModality for first treatment descriptions #################
data_process <- data_process %>% 
  mutate(CancerTreatmentModality = case_when(
    CancerTreatmentModality == "1" ~ "Surgery",
    CancerTreatmentModality == "2" ~ "Anti-Cancer Drug Regimen (Cytotoxic Chemotherapy)",
    CancerTreatmentModality == "3" ~ "Anti-Cancer Drug Regimen (Hormone Therapy)",
    CancerTreatmentModality == "4" ~ "Chemoradiotherapy",
    CancerTreatmentModality == "5" ~ "Teletherapy (Beam Radiation excluding Proton Therapy)",
    CancerTreatmentModality == "6" ~ "Brachytherapy",
    CancerTreatmentModality == "7" ~ "Specialist Palliative Care",
    CancerTreatmentModality == "8" ~ "Active Monitoring (excluding Non-Specialist Palliative Care)",
    CancerTreatmentModality == "9" ~ "Non-Specialist Palliative Care (excluding Active Monitoring)",
    CancerTreatmentModality == "10" ~ "Radiofrequency Ablation (RFA)",
    CancerTreatmentModality == "11" ~ "High Intensity Focused Ultrasound (HIFU)",
    CancerTreatmentModality == "12" ~ "Cryotherapy",
    CancerTreatmentModality == "13" ~ "Proton Therapy",
    CancerTreatmentModality == "14" ~ "Anti-Cancer Drug Regimen (other)",
    CancerTreatmentModality == "15" ~ "Anti-Cancer Drug Regimen (Immunotherapy)",
    CancerTreatmentModality == "16" ~ "Light Therapy (including Photodynamic Therapy and Psoralen and Ultraviolet A Therapy (PUVA))",
    CancerTreatmentModality == "17" ~ "Hyperbaric Oxygen Therapy",
    CancerTreatmentModality == "18" ~ "Other Treatment (Retired 1 July 2012)",
    CancerTreatmentModality == "19" ~ "Radioisotope Therapy (including Radioiodine)",
    CancerTreatmentModality == "20" ~ "Laser Treatment (including Argon Beam therapy)",
    CancerTreatmentModality == "21" ~ "Biological Therapies (excluding Immunotherapy)",
    CancerTreatmentModality == "22" ~ "Radiosurgery",
    CancerTreatmentModality == "23" ~ "Surgery (excluding enabling treatment)",
    CancerTreatmentModality == "24" ~ "Surgery (enabling treatment)",
    CancerTreatmentModality == "97" ~ "Other treatment (not listed)",
    CancerTreatmentModality == "98" ~ "All treatment declined")
  )

# Reformat data to suit eventlog in bupaR package ##############################
data_process <- data_process |> 
  mutate(CancerTreatmentModality = as.character(CancerTreatmentModality))

# Reshape data to long format
data_process2 <- data_process %>% 
  pivot_longer(cols = c("CancerReferralToTreatmentPeriodStartDate", "ConsultantUpgradeDate",
                        "DateFirstSeen", 
                        "CancerFasterDiagnosisPathwayEndDate",
                        
                        "ServiceRequestedDateInterProviderTransfer1",
                        "ReferralRequestReceivedDateInterProviderTransfer1",
                        
                        "ServiceRequestedDateInterProviderTransfer2",
                        "ReferralRequestReceivedDateInterProviderTransfer2",
                        
                        "ServiceRequestedDateInterProviderTransfer3",
                        "ReferralRequestReceivedDateInterProviderTransfer3",
                        
                        "ServiceRequestedDateInterProviderTransfer4",
                        "ReferralRequestReceivedDateInterProviderTransfer4",
                        
                        "ServiceRequestedDateInterProviderTransfer5",
                        "ReferralRequestReceivedDateInterProviderTransfer5",
                        
                        "ServiceRequestedDateInterProviderTransfer6",
                        "ReferralRequestReceivedDateInterProviderTransfer6",
                        
                        "ServiceRequestedDateInterProviderTransfer7",
                        "ReferralRequestReceivedDateInterProviderTransfer7",
                        
                        "ServiceRequestedDateInterProviderTransfer8",
                        "ReferralRequestReceivedDateInterProviderTransfer8",
                        
                        "ServiceRequestedDateInterProviderTransfer9",
                        "ReferralRequestReceivedDateInterProviderTransfer9",
                        
                        "ServiceRequestedDateInterProviderTransfer10",
                        "ReferralRequestReceivedDateInterProviderTransfer10",
                        
                        "CancerTreatmentPeriodStartDate", 
                        "TreatmentStartDateCancer",
                        ), names_to = "milestone", values_to = "timestamp")

# Add event description and site code to the Stage variable
data_process3 <- data_process2 %>% 
  mutate(Stage = case_when(
                    milestone == "CancerReferralToTreatmentPeriodStartDate" ~ paste0("RTT Start", "-", OrganisationIdentifierPatientPathwayIdentifierIssuer),
                    milestone == "ConsultantUpgradeDate" ~ paste0("Consultant Upgrade", "-", OrganisationSiteIdentifierOfProviderConsultantUpgrade),
                    milestone == "DateFirstSeen" ~ paste0("FirstSeen", "-", OrganisationSiteIdentifierOfProviderFirstSeen),
                    milestone == "CancerFasterDiagnosisPathwayEndDate" ~ paste0("Diagnosis", "-", OrganisationSiteIdentifierOfCancerFasterDiagnosisEnd),
                    milestone == "ServiceRequestedDateInterProviderTransfer1" ~ paste0("IPT Request", "-", OrganisationIdentifierReferring1),
                    milestone == "ReferralRequestReceivedDateInterProviderTransfer1" ~ paste0("IPT Received", "-", OrganisationIdentifierReceiving1),
                    
                    milestone == "ServiceRequestedDateInterProviderTransfer2" ~ paste0("IPT Request", "-", OrganisationIdentifierReferring2),
                    milestone == "ReferralRequestReceivedDateInterProviderTransfer2" ~ paste0("IPT Received", "-", OrganisationIdentifierReceiving2),
                    
                    milestone == "ServiceRequestedDateInterProviderTransfer3" ~ paste0("IPT Request", "-", OrganisationIdentifierReferring3),
                    milestone == "ReferralRequestReceivedDateInterProviderTransfer3" ~ paste0("IPT Received", "-", OrganisationIdentifierReceiving3),
                    
                    milestone == "ServiceRequestedDateInterProviderTransfer4" ~ paste0("IPT Request", "-", OrganisationIdentifierReferring4),
                    milestone == "ReferralRequestReceivedDateInterProviderTransfer4" ~ paste0("IPT Received", "-", OrganisationIdentifierReceiving4),
                    
                    milestone == "ServiceRequestedDateInterProviderTransfer5" ~ paste0("IPT Request", "-", OrganisationIdentifierReferring5),
                    milestone == "ReferralRequestReceivedDateInterProviderTransfer5" ~ paste0("IPT Received", "-", OrganisationIdentifierReceiving5),
                    
                    milestone == "ServiceRequestedDateInterProviderTransfer6" ~ paste0("IPT Request", "-", OrganisationIdentifierReferring6),
                    milestone == "ReferralRequestReceivedDateInterProviderTransfer6" ~ paste0("IPT Received", "-", OrganisationIdentifierReceiving6),
                    
                    milestone == "ServiceRequestedDateInterProviderTransfer7" ~ paste0("IPT Request", "-", OrganisationIdentifierReferring7),
                    milestone == "ReferralRequestReceivedDateInterProviderTransfer7" ~ paste0("IPT Received", "-", OrganisationIdentifierReceiving7),
                    
                    milestone == "ServiceRequestedDateInterProviderTransfer8" ~ paste0("IPT Request", "-", OrganisationIdentifierReferring8),
                    milestone == "ReferralRequestReceivedDateInterProviderTransfer8" ~ paste0("IPT Received", "-", OrganisationIdentifierReceiving8),
                    
                    milestone == "ServiceRequestedDateInterProviderTransfer9" ~ paste0("IPT Request", "-", OrganisationIdentifierReferring9),
                    milestone == "ReferralRequestReceivedDateInterProviderTransfer9" ~ paste0("IPT Received", "-", OrganisationIdentifierReceiving9),
                    
                    milestone == "ServiceRequestedDateInterProviderTransfer10" ~ paste0("IPT Request", "-", OrganisationIdentifierReferring10),
                    milestone == "ReferralRequestReceivedDateInterProviderTransfer10" ~ paste0("IPT Received", "-", OrganisationIdentifierReceiving10),
                    
                    milestone == "CancerTreatmentPeriodStartDate" ~ paste0("Decision to Treat", "-", OrganisationSiteIdentifierOfProviderCancerDecisionToTreat),
                    milestone == "TreatmentStartDateCancer" ~ paste0(CancerTreatmentModality, "-", OrganisationSiteIdentifierOfProviderCancerTreatmentStartDate))
  )

# Sort the dataframe to recognise timestamps
data_process4 <- data_process3 %>% 
  mutate(timestamp = as.Date(timestamp)) %>% 
  group_by(CwtPatientRecordId) %>% 
  arrange(CwtPatientRecordId, !is.na(timestamp), timestamp) %>% 
  fill(timestamp, .direction = "up")

# De-duplicate rows if two tumour lateralities present
data_process4 <- data_process4 |> 
  distinct()

# Add order to rows and a common end stage and common resource
data_process5 <- data_process4 %>% 
  ungroup() %>% 
  mutate(activity_instance_id = row_number(),
         lifecycle = "completed",
         resource = "nhs_staff")

# Organise variables in eventlog
data_process6 <- eventlog(data_process5, case_id = "CwtPatientRecordId", activity_id = "Stage", activity_instance_id = "activity_instance_id", lifecycle_id = "lifecycle", timestamp = "timestamp", resource_id = "resource")

# Remove non-consultant upgrade milestones
data_process6 <- data_process6 |> 
  filter(!Stage == "RTT Start-none",
         !Stage == "Consultant Upgrade-none",
         !Stage == "FirstSeen-none",
         !Stage == "Diagnosis-none",
         !Stage == "IPT Request-none",
         !Stage == "IPT Received-none",
         !Stage == "Decision to Treat-none"
         )

# Create table of patient numbers per stage
data_patient_numbers_62 <- data_process6 |> 
  dplyr::group_by(OrganisationSiteIdentifierOfProviderCancerTreatmentStartDate, CancerTreatmentModality) |> 
  summarise(no_of_patients = n_distinct(CwtPatientRecordId))

# Filter for X% most frequent pathways taken ###################################
process_30per <- data_process6 %>% 
  filter_trace_frequency(percentage = 0.30)

process_50per <- data_process6 %>% 
  filter_trace_frequency(percentage = 0.50)

process_80per <- data_process6 %>% 
  filter_trace_frequency(percentage = 0.80)

process_100per <- data_process6 %>% 
  filter_trace_frequency(percentage = 1.00)

### Generate the RMarkdown file#################################################
rmarkdown::render("scripts/Gynae_Uterus_Process_Mining_WMCA.rmd",
                  output_dir = "outputs/",
                  quiet = TRUE
)
################################################################################
# Create individual provider pathways based on OrganisationSiteIdentifierOfProviderCancerDecisionToTreat

Providers_DTT <- unique(data_process6$OrganisationSiteIdentifierOfProviderCancerDecisionToTreat)

for (x in Providers_DTT) {

data_process7 <- data_process6 |> 
  filter(OrganisationSiteIdentifierOfProviderCancerDecisionToTreat == x)

# Create table of patient numbers per stage
data_patient_numbers_62 <- data_process7 |> 
  dplyr::group_by(OrganisationSiteIdentifierOfProviderCancerTreatmentStartDate, CancerTreatmentModality) |> 
  summarise(no_of_patients = n_distinct(CwtPatientRecordId))

# Filter for X% most frequent pathways taken ###################################
process_30per <- data_process7 %>% 
  filter_trace_frequency(percentage = 0.30)

process_50per <- data_process7 %>% 
  filter_trace_frequency(percentage = 0.50)

process_80per <- data_process7 %>% 
  filter_trace_frequency(percentage = 0.80)

process_100per <- data_process7 %>% 
  filter_trace_frequency(percentage = 1.00)

### Generate the RMarkdown file#################################################
rmarkdown::render("scripts/Gynae_Uterus_Process_Mining_Trusts.rmd",
                  output_file = paste0('Gynae_Uterus_Process_Mining_', x, '.html'),
                  output_dir = "outputs/",
                  quiet = TRUE
)
}

# End ##########################################################################
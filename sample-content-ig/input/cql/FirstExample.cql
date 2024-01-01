library FirstExample version '0.1.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1'

codesystem "SNOMED-CT": 'http://snomed.info/sct'
codesystem "LOINC": 'http://loinc.org'
codesystem "ICD-10": 'http://hl7.org/fhir/sid/icd-10'

valueset "Marital Status": 'http://hl7.org/fhir/ValueSet/marital-status'
valueset "Condition Clinical Status": 'http://utah.edu/fhir/lcs-cds/ValueSet/conditionclinical'

code "Human immunodeficiency virus [HIV] disease": 'B20' from "ICD-10" display 'HIV disease'
code "Asymptomatic human immunodeficiency virus [HIV] infection status": 'Z21' from "ICD-10" display 'HIV disease no symptoms'
code "HIV Antiretroviral therapy Antiretroviral therapy status section": '47248-0' from "LOINC" display 'ART Status'
code "HIV 1 RNA [#/volume] (viral load) in Serum or Plasma by Probe" : '21008-8' from "LOINC" display 'HIV Viral Load'

// HIV Test result (without details of the specific type of test used)
code "HIV Negative": '165815009' from "SNOMED-CT"
code "HIV Positive": '165816005' from "SNOMED-CT"

parameter "Measurement Period" default Interval[@1970-01-01T00:00:00.000, @2023-10-27T00:00:00.000]

/*******************************************************************************************************************/


// aufteilung insgesamt 10/10/10 introduction & background, design & impl, & architec, evaluation & conclusion & discussion
// statistik austria, wie wird aktuell erfasst wv patienten positiv sind


/*******************************************************************************************************************/


//TODO
// deceased : false for minimum data
// more information e.g. age groups, gender, key populations? 
// test result for 1. indicator (https://ecqi.healthit.gov/sites/default/files/ecqm/measures/CMS349v4.html#d1e405)

/*******************************************************************************************************************/


// 95% that live with HIV will have been tested and know their status
// Numerator:
//    Patients, regardless of age
//    Diagnosis of HIV/AIDS (ICD-10): B20, Z21
//    Received HIV Testing Services (HTS) and their first test result

//    are alive?
//    viral load > 200?
// Denominator: 
//    none

// 95% diagnosed, receive sustained art
// Numerator:
//    Patients, regardless of age
//    Diagnosis of HIV/AIDS (ICD-10): B20, Z21
//    Patient Observation, receives ART (LOINC): 47248-0
//    Patient Encounter during the performance period (CPT or HCPCS): 99201, 99202, 99203, 99204, 99205, 99212, 99213, 99214, 99215, G0402 
//    are alive?
// Denominator: 
//     number of people aged 15-65 living with HIV (positive Diagnosis)

// 95% diagnosed, receive sustained art and achieve viral suppresions
// Numerator: 
//    Patients, regardless of age
//    Diagnosis of HIV/AIDS (ICD-10): B20, Z21
//    Patient Observation, receives art (LOINC): 47248-0
//    Patient Observation, achieve Viralsuppression
//    are alive?    
//    Patient Encounter during the performance period (CPT or HCPCS): 99201, 99202, 99203, 99204, 99205, 99212, 99213, 99214, 99215, G0402 
// Denominator: 
//     Number of Patients with a HIV viral load less than 200 copies/mililiter at last viral load test

context Patient

define "Initial Population":
  Denominator

define Numerator:
  "On ART" and "HIV Condition"

define Denominator:
  "Patient 15 to 65" and "HIV Condition"

define "Patient 15 to 65":
  exists(
    [Patient] p
    where CalculateAgeInYears(p.birthDate.value) >= 15 or CalculateAgeInYears(p.birthDate.value) <= 65
  )

// diagnosed who receive sustained ART, achieve viral suppressions
define "Receive sustained Viral suppression":
  "HIV Condition" and "On ART" and "Suppressed viral load (<200 copies/mL)"

define "HIV Condition":
  exists(
    [Condition: "Human immunodeficiency virus [HIV] disease"] H
    where H.clinicalStatus in "Condition Clinical Status"
  )
  or exists(
    [Condition: "Asymptomatic human immunodeficiency virus [HIV] infection status"] HNOS
    where HNOS.clinicalStatus in "Condition Clinical Status"
  )

// TODO 1. Indicator, Test Result missing
define "Know their status":
  "HIV Condition"

// 2. Indicator
define "On ART":
  exists(
    [Observation] ARTValidation
      where "HIV Antiretroviral therapy Antiretroviral therapy status section".code in ARTValidation.code.coding.code
      and ARTValidation.status in {'final', 'amended', 'corrected'}
      and "Recent ART Observation"
    )

// 3. Indicator
define "Suppressed viral load (<200 copies/mL)":
exists(
  [Observation] ViralsuppressionValidation
  where "HIV 1 RNA [#/volume] (viral load) in Serum or Plasma by Probe".code in ViralsuppressionValidation.code.coding.code
  and ViralsuppressionValidation.status in {'final', 'amended', 'corrected'}
  and exists(
    [Observation] ViralSuppresionValue
    where ViralSuppresionValue.value.as(Quantity).value < 200
  )
)
  
//achieved viral suppression in the last 6 months
define "Recent Viral suppression Observation":
  exists(
    [Observation] RecentObservation
    where date from RecentObservation.effective in Interval[date from end of "Measurement Period" - 6 months, date from end of "Measurement Period"]
  )

// received ART in the last 3 months
define "Recent ART Observation":
  exists(
    [Observation] RecentObservation
    where date from RecentObservation.effective in Interval[date from end of "Measurement Period" - 3 months, date from end of "Measurement Period"]
  )

define "getAge":
  AgeInYears()


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
code "HIV 1 RNA [#/volume] (viral load) in Serum or Plasma by NAA with probe detection" : '20447-9' from "LOINC" display 'Viral Load Test'

// HIV Test result (without details of the specific type of test used)
code "HIV Negative": '165815009' from "SNOMED-CT"
code "HIV Positive": '165816005' from "SNOMED-CT"

// abbreviation chapter; nach table of contents?
// neue chapter: passt der inhalt? wieviele seiten gesamt? 10?
// aufteilung insgesamt 10/10/10 introduction & background, design & impl, & architec, evaluation & conclusion & discussion
// synthea?
// Interval hard codiert aktuell
// VALUE SET?????????
// FHIR HELPER VERSION??????
// ist effectivedatetime das richtige kriterium? oder lieber etwas wie G0402 follow up visit for a medicare...
// 1. parameter..
// 3. parameter denom?
// pro parameter, eigene library/cql file? alternative mehrere outputparameter denom1 num1, denom2...
// wie funktioniert das technisch?

//TODO
// deceased : false for minimum data
// outpatient visit

//library, parameter DT
// input measurement parameter
// statistik austria, wie wird aktuell erfasst wv patienten positiv sind
// measure, library anschauen, input output parameter definieren

parameter "Measurement Period" default Interval[@1970-01-01T00:00:00.000, @2023-10-27T00:00:00.000]

context Patient

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
//    
//    Patient Encounter during the performance period (CPT or HCPCS): 99201, 99202, 99203, 99204, 99205, 99212, 99213, 99214, 99215, G0402 
// Denominator: 
//     Number of Patients with a HIV viral load less than 200 copies/mililiter at last viral load test

define "Initial Population":
  Denominator

define Numerator:
  "Receive sustained ART"

define Denominator:
  Patient15To65 and "HIV diagnosis"

define "Patient15To65":
  exists(
    [Patient] p
    where CalculateAgeInYears(p.birthDate.value) >= 15 or CalculateAgeInYears(p.birthDate.value) <= 65
  )

// diagnosed receive sustained art
define "Receive sustained ART":
  "HIV diagnosis" and "Receive ART" and "Recent ART Observation" 

// diagnosed who receive sustained ART, achieve viral suppressions
define "Receive sustained Viral suppression":
  "HIV diagnosis" and "Receive ART" and "Achieve Viral suppression" and "Recent Viral suppression Observation"

define "HIV diagnosis":
  exists(
    [Condition: "Human immunodeficiency virus [HIV] disease"] H
    where H.clinicalStatus in "Condition Clinical Status"
  )
  or exists(
    [Condition: "Asymptomatic human immunodeficiency virus [HIV] infection status"] HNOS
    where HNOS.clinicalStatus in "Condition Clinical Status"
  )

// TODO 1. HIV Test Result

// 2.
define "Receive ART":
  exists(
    [Observation] ARTValidation
      where "HIV Antiretroviral therapy Antiretroviral therapy status section".code in ARTValidation.code.coding.code
      and ARTValidation.status in {'final', 'amended', 'corrected'}
  )
// 3.
define "Achieve Viral suppression":
  exists(
    [Observation] ViralsuppressionValidation
    where "HIV 1 RNA [#/volume] (viral load) in Serum or Plasma by NAA with probe detection".code in ViralsuppressionValidation.code.coding.code
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


--1. a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims. 

--total_claim_count per drug/ npi 1912011792 has total of 4538 claims for drug_name "OXYCODONE HCL".
SELECT npi, drug_name, total_claim_count
FROM prescription  
GROUP BY npi, drug_name, total_claim_count
ORDER BY total_claim_count DESC
Limit 100

---npi 1881634483 has the most total claims (299,121)
SELECT npi, SUM (total_claim_count) AS total_claims 
FROM prescription 
GROUP BY npi
ORDER BY total_claims DESC

--b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, and the total number of claims.
--BRUCE PENDLEY, Family Practice has the highest number of claims (897363)
SELECT p1.npi, 
	p2.nppes_provider_first_name, 
	p2.nppes_provider_last_org_name,  
	p2.specialty_description, 
	SUM(p1.total_claim_count) AS total_claims
FROM prescription AS p1
LEFT JOIN prescriber AS p2
ON p1.npi = p2.npi
GROUP BY 1,2,3,4
ORDER BY 5 DESC


select nppes_provider_first_name, 
	nppes_provider_last_org_name, 
	specialty_description, 
	npi, 
	sum(total_claim_count) as total_claims
from prescription 
inner join prescriber 
USING (npi)
group by npi, nppes_provider_first_name, nppes_provider_last_org_name, specialty_description
order by total_claims desc
limit 1


--first name and last name in one column
SELECT
	p1.npi,
	p1.nppes_provider_first_name || ' ' || p1.nppes_provider_last_org_name AS name,
	p1.specialty_description AS specialty,
	SUM(p2.total_claim_count) AS total_claims
FROM prescriber p1
JOIN prescription p2 ON p1.npi = p2.npi
GROUP BY 1,2,3
ORDER BY 4 DESC



--2. a. Which specialty had the most total number of claims (totaled over all drugs)?

--family practice specialty has the highest number of claims (87,771,123)
SELECT p2.specialty_description, 
		SUM(p1.total_claim_count) AS total_claims
FROM prescription AS p1
LEFT JOIN prescriber AS p2
ON p1.npi = p2.npi
GROUP BY 1
ORDER BY 2 DESC

--b. Which specialty had the most total number of claims for opioids?
--Nurse Practitioner had the most total claims (8107605)
SELECT specialty_description, 
		TO_CHAR(SUM (total_claim_count), 'fm999G999D99') AS total_claims
FROM prescription 
INNER JOIN prescriber 
USING (npi)
WHERE prescription.drug_name IN 
	(SELECT drug.drug_name 
	 FROM drug
	 WHERE opioid_drug_flag='Y'
	)
GROUP BY specialty_description
ORDER BY total_claims DESC;



SELECT specialty_description, 
		SUM(total_claim_count) AS total_claims
FROM prescription
INNER JOIN prescriber
USING (npi)
INNER JOIN drug
USING (drug_name)
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty_description
ORDER BY total_claims DESC;


--c. Challenge Question: Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
--There are 15 specialties that appear only in the prescriber table
SELECT DISTINCT specialty_description 
FROM prescriber 
WHERE specialty_description NOT IN 
	(SELECT DISTINCT specialty_description 
	 FROM prescriber
	 WHERE npi IN
		(SELECT npi
		FROM prescription)
	)

SELECT DISTINCT specialty_description, 
				SUM(total_claim_count) AS total_claims
FROM prescriber
FULL JOIN prescription
ON prescriber.npi = prescription.npi
GROUP BY specialty_description
HAVING (SUM(total_claim_count) IS NULL)
ORDER BY total_claims;


SELECT
	p1.specialty_description AS specialty,
	COALESCE(SUM(p2.total_claim_count), 0) AS total_claims
FROM prescriber p1
LEFT JOIN prescription p2 ON p1.npi = p2.npi
GROUP BY 1
ORDER BY 2 ;


/*d. Difficult Bonus: Do not attempt until you have solved all other problems! For each specialty, report the percentage of
total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?*/



--3. a. Which drug (generic_name) had the highest total drug cost?
--"PIRFENIDONE"
SELECT generic_name, 
		MAX(total_drug_cost) AS most_expensive_drug
FROM drug
INNER JOIN prescription 
USING (drug_name)
WHERE total_drug_cost IS NOT NULL
GROUP BY generic_name 
ORDER BY most_expensive_drug DESC


SELECT generic_name, total_drug_cost
FROM prescription
LEFT JOIN drug
USING (drug_name)
order by total_drug_cost DESC
limit 1

--this gives us "INSULIN GLARGINE,HUM.REC.ANLOG"
SELECT generic_name, SUM(total_drug_cost)::MONEY
FROM prescription 
INNER JOIN drug
USING(drug_name)
GROUP BY generic_name
ORDER BY 2 DESC;

/*b. Which drug (generic_name) has the hightest total cost per day? 
**Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.*/
--"C1 ESTERASE INHIBITOR" has the highest cost per day

SELECT generic_name, 
		ROUND(SUM(total_drug_cost)/SUM(total_day_supply), 2)
FROM prescription
LEFT JOIN drug
USING (drug_name)
GROUP BY generic_name
ORDER BY 2 DESC
LIMIT 1;

/* 4. a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 
'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', 
and says 'neither' for all other drugs. */

SELECT drug_name,
		CASE 
			WHEN opioid_drug_flag='Y' THEN 'opioid'
			WHEN antibiotic_drug_flag='Y' THEN 'antibiotic'
			ELSE 'neither'
		END AS drug_type
FROM drug
ORDER BY drug_type

/* b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. 
Hint: Format the total costs as MONEY for easier comparision. */

--more money is sepnt on opioids ($945,725,637.33) than antibiotics ($345,916,091.34)
SELECT 
		CASE 
			WHEN opioid_drug_flag='Y' THEN 'opioid'
			WHEN antibiotic_drug_flag='Y' THEN 'antibiotic'
			ELSE 'neither'
		END AS drug_type,
		SUM(total_drug_cost)::money AS total_drug_cost
FROM drug
INNER JOIN prescription 
USING (drug_name)
GROUP BY drug_type
ORDER BY total_drug_cost DESC 


--using cte
WITH cteDrugType AS
(
	SELECT drug_name,
		CASE WHEN opioid_drug_flag = 'Y'     THEN 'opioid'
			 WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
			 ELSE 'neither'
		END AS drug_type
	FROM drug
)
SELECT DISTINCT cdt.drug_type, 
	SUM(p.total_drug_cost::money) AS drug_cost
FROM cteDrugType cdt
INNER JOIN prescription p
ON cdt.drug_name = p.drug_name
WHERE cdt.drug_type <> 'neither'
GROUP BY cdt.drug_type
ORDER BY drug_cost DESC;



SELECT drug_type, 
		SUM(total_drug_cost :: MONEY)
FROM prescription as p
FULL JOIN
(SELECT drug_name,
 CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
        -- Second case
        WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
        -- Else clause + end
        ELSE 'neither' 
		END AS drug_type
FROM drug) AS flags
USING (drug_name)
WHERE drug_type = 'opioid' OR drug_type = 'antibiotic'
GROUP BY drug_type
order by SUM(total_drug_cost:: MONEY) desc;


--count of opioid drugs
SELECT
	drug_name,
	COUNT(DISTINCT opioid_drug_flag)
FROM drug
GROUP BY 1
ORDER BY 2 DESC

-- 5a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
--There are 10 CBSAs
SELECT COUNT (DISTINCT cbsaname)
FROM cbsa
INNER JOIN fips_county
USING (fipscounty)
WHERE state='TN'
	   

SELECT COUNT(DISTINCT cbsa)
FROM cbsa
WHERE cbsaname LIKE '%TN%';


SELECT COUNT (DISTINCT cbsaname)
FROM fips_county
INNER JOIN cbsa
USING (fipscounty)
WHERE state='TN'

-- b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
--Nashville has the largest population (49,421,070)
SELECT cbsaname,
	   SUM(population) AS total_population 
FROM cbsa
INNER Join fips_county
USING (fipscounty)
INNER Join population
USING (fipscounty)
GROUP BY cbsaname
ORDER BY total_population DESC
	   

--Morristown has the smallest population (3141504)
SELECT cbsaname,
	   SUM(population) AS total_population 
FROM cbsa
INNER Join fips_county
USING (fipscounty)
INNER Join population
USING (fipscounty)
GROUP BY cbsaname
ORDER BY total_population 

		
-- 5c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
--Sevier with population of 95,523 is the largest county not included in a CBSA
SELECT county, 
		population
FROM cbsa
RIGHT JOIN fips_county
USING (fipscounty)
INNER JOIN population
USING (fipscounty)
WHERE state='TN'
AND cbsa IS NULL
ORDER BY population DESC 

SELECT population, county
FROM population
FULL JOIN cbsa
USING (fipscounty)
FULL JOIN fips_county
USING (fipscounty)
WHERE cbsa IS NULL
AND population IS NOT NULL
ORDER BY population DESC


SELECT county, state, SUM(population) AS total_pop
FROM fips_county
INNER JOIN population
USING(fipscounty)
WHERE county NOT IN 
(
	SELECT county
	FROM cbsa
	INNER JOIN fips_county
	USING(fipscounty)
	WHERE cbsaname LIKE '%TN%'
)
GROUP BY county,state
ORDER BY total_pop DESC;

-- 6. a. Find all rows in the prescription table where total_claims are at least 3000. Report the drug_name and the total_claim_count.
--"OXYCODONE HCL" drug name
SELECT drug_name, total_claim_count
FROM prescription 
WHERE total_claim_count >=3000
ORDER BY total_claim_count DESC

-- b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
SELECT drug_name, total_claim_count,
		CASE WHEN opioid_drug_flag='Y' THEN 'opioid'
			ELSE 'not opioid'
			END AS is_opioid
FROM prescription 
INNER JOIN drug
USING (drug_name)
WHERE total_claim_count >=3000
ORDER BY total_claim_count 

-- c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

SELECT drug_name, total_claim_count,
		nppes_provider_first_name, 
		nppes_provider_last_org_name, 
		CASE WHEN opioid_drug_flag='Y' THEN 'opioid'
			ELSE 'not opioid'
			END AS is_opioid
FROM prescription 
INNER JOIN drug
USING (drug_name)
INNER JOIN prescriber 
USING (npi)
WHERE total_claim_count >=3000
ORDER BY total_claim_count DESC


/* 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville 
and the number of claims they had for each opioid. */

/* a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management') 
in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). 
**Warning:** Double-check your query before running it. You will likely only need to use the prescriber and drug tables. */

SELECT npi, drug_name
FROM prescriber AS p
CROSS JOIN drug AS d
WHERE p.specialty_description='Pain Management'
AND p.nppes_provider_city = 'NASHVILLE'
AND d.opioid_drug_flag = 'Y'


/* 7b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or 
not the prescriber had any claims. You should report the npi, the drug name, and the number of claims 
(total_claim_count). */

SELECT npi, drug_name, sum(total_claim_count) AS total_claim_count
FROM prescriber
FULL JOIN prescription
USING (npi)
FULL JOIN drug
USING (drug_name)
WHERE specialty_description='Pain Management'
AND nppes_provider_city = 'NASHVILLE'
AND opioid_drug_flag = 'Y'
GROUP BY npi, drug_name
LIMIT 10


-- 7c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.

SELECT npi, 
		drug_name, 
		COALESCE(total_claim_count, 0) AS total_claim_count
FROM prescriber
FULL JOIN prescription
USING (npi)
FULL JOIN drug
USING (drug_name)
WHERE specialty_description='Pain Management'
AND nppes_provider_city = 'NASHVILLE'
AND opioid_drug_flag = 'Y'
GROUP BY npi, drug_name, total_claim_count
ORDER BY total_claim_count DESC
LIMIT 10


--PART 2

--1. How many npi numbers appear in the prescriber table but not in the prescription table?
--75150
SELECT COUNT(npi)
FROM prescriber 
WHERE npi NOT IN 
	(SELECT npi
	FROM prescription
	 )

--2.a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.

SELECT generic_name, SUM(total_claim_count) AS sum_total_count
FROM prescriber
INNER JOIN prescription
USING (npi)
INNER JOIN drug
USING(drug_name)
WHERE specialty_description= 'Family Practice'
GROUP BY generic_name
ORDER BY sum_total_count DESC



--b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.
SELECT generic_name, SUM(total_claim_count) AS sum_total_count
FROM prescriber
INNER JOIN prescription
USING (npi)
INNER JOIN drug
USING(drug_name)
WHERE specialty_description= 'Cardiology'
GROUP BY generic_name
ORDER BY sum_total_count DESC


--c. Which drugs appear in the top five prescribed for both Family Practice prescribers and Cardiologists? Combine what you did for parts a and b into a single query to answer this question.
SELECT generic_name, SUM(total_claim_count) AS sum_total_count
FROM prescriber
INNER JOIN prescription
USING (npi)
INNER JOIN drug
USING(drug_name)
WHERE specialty_description= 'Family Practice' OR specialty_description= 'Cardiology'
GROUP BY generic_name
ORDER BY sum_total_count DESC


--3. Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee.
--a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. 
--Report the npi, the total number of claims, and include a column showing the city.
--b. Now, report the same for Memphis.
--c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.



SELECT npi, 
		SUM(total_claim_count) AS total_num_claims, 
		nppes_provider_first_name || ' ' || nppes_provider_last_org_name AS provider, 
		nppes_provider_city 
FROM prescriber
INNER JOIN prescription 
USING (npi)
INNER JOIN drug
USING (drug_name)
WHERE nppes_provider_city = 'MEMPHIS' OR nppes_provider_city = 'NASHVILLE' OR nppes_provider_city = 'KNOXVILLE' OR nppes_provider_city = 'CHATTANOOGA'
GROUP BY npi, provider, nppes_provider_city
ORDER BY total_num_claims DESC
LIMIT 20

--4. Find all counties which had an above-average (for the state) number of overdose deaths in 2017. 
--Report the county name and number of overdose deaths.

SELECT county, state, overdose_deaths
FROM fips_county
INNER JOIN overdose_deaths
USING(fipscounty)
WHERE year='2017' AND overdose_deaths >
	(SELECT AVG(overdose_deaths) AS avg_overdose_deaths
	FROM overdose_deaths
	INNER JOIN fips_county 
	USING (fipscounty)
	WHERE year='2017' AND state='TN')
GROUP BY county, state, overdose_deaths
ORDER By overdose_deaths DESC


--5.a. Write a query that finds the total population of Tennessee.
--population is 6,597,381
SELECT SUM(population) AS state_pop
FROM population
INNER JOIN fips_county
USING (fipscounty)


--b. Build off of the query that you wrote in part a to write a query that returns for each county that county's name, 
--its population, and the percentage of the total population of Tennessee that is contained in that county.

SELECT county, population, round(100 * population / (SELECT sum(population) 
	FROM population
	INNER JOIN fips_county
	USING (fipscounty)), 2) AS percent_population
FROM population
INNER JOIN fips_county
USING (fipscounty)

--with CTE
WITH state_pop AS 
(
SELECT SUM(population) AS state_population
FROM population
INNER JOIN fips_county
USING (fipscounty)
),

county_pop AS 
(
SELECT county, SUM(population) AS county_population
FROM population
INNER JOIN fips_county
USING (fipscounty)
GROUP BY county
)

SELECT county, county_population,
	ROUND(county_population * 100.00/ (SELECT state_population FROM state_pop), 2) AS percentage
	FROM county_pop
	




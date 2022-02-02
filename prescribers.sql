---1. a. Which prescriber had the highest total number of claims (totaled over all drugs)? 
--Report the npi and the total number of claims.
SELECT npi, drug_name, total_claim_count
FROM prescription  
GROUP BY npi, drug_name, total_claim_count
ORDER BY total_claim_count DESC
Limit 100

---b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,
---specialty_description, and the total number of claims.

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



SELECT p2.specialty_description, 
		SUM(p1.total_claim_count) AS total_claims
FROM prescription AS p1
LEFT JOIN prescriber AS p2
ON p1.npi = p2.npi
GROUP BY 1
ORDER BY 2 DESC





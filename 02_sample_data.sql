INSERT INTO threat_actors (actor_name, region, sophistication_tier, is_state_backed) VALUES
('Cosmic Leopard', 'APAC', 'NATION-STATE', TRUE),
('Void Requiem', 'EMEA', 'CRIMINAL', FALSE),
('Sandstorm Collective', 'NAR', 'HACKTIVIST', FALSE),
('Crimson Hydra', 'GLOBAL', 'NATION-STATE', TRUE),
('Phantom Guild', 'EMEA', 'CRIMINAL', FALSE);

INSERT INTO tools (tool_name, tool_type, is_commodity) VALUES
('Kraken RAT', 'MALWARE', FALSE),
('PhishTrap Framework', 'SOCIAL_ENGINEERING', TRUE),
('Zero-Day: Phoenix', 'EXPLOIT', FALSE),
('DarkMesh VPN', 'INFRASTRUCTURE', TRUE),
('BruteForce XLR', 'CREDENTIAL_ACCESS', TRUE);

INSERT INTO incidents (actor_id, tool_id, incident_date, severity_score, target_sector, description) VALUES
(1, 1, '2025-01-15', 9, 'GOVERNMENT', 'Supply chain compromise via malicious update'),
(2, 2, '2025-01-20', 5, 'FINANCE', 'CEO spearphishing attempt, blocked by filters'),
(1, 3, '2025-01-25', 10, 'DEFENSE', 'Critical infrastructure zero-day exploitation'),
(3, NULL, '2025-02-01', 7, 'ENERGY', 'DDoS attack on grid management systems'),
(4, 4, '2025-02-05', 8, 'TELECOM', 'Long-term network infiltration detected'),
(2, 5, '2025-02-10', 6, 'HEALTHCARE', 'Patient data exfiltration attempt'),
(5, 2, '2025-02-15', 4, 'EDUCATION', 'Widespread phishing campaign'),
(1, NULL, '2025-02-20', 9, 'FINANCE', 'SWIFT network intrusion detected'),
(4, 3, '2025-02-25', 10, 'DEFENSE', 'Weapons system firmware compromise');
SELECT 
    i.incident_id,
    i.incident_date,
    ta.actor_name,
    ta.region as actor_region,
    ta.sophistication_tier,
    t.tool_name,
    i.severity_score,
    i.target_sector,
    i.description
FROM incidents i
INNER JOIN threat_actors ta ON i.actor_id = ta.actor_id
LEFT JOIN tools t ON i.tool_id = t.tool_id
ORDER BY i.incident_date DESC, i.severity_score DESC;


SELECT 
    ta.actor_id,
    ta.actor_name,
    ta.region,
    ta.sophistication_tier,
    ta.is_state_backed,
    COUNT(i.incident_id) as incident_count
FROM threat_actors ta
LEFT JOIN incidents i ON ta.actor_id = i.actor_id
GROUP BY ta.actor_id, ta.actor_name, ta.region, ta.sophistication_tier, ta.is_state_backed
HAVING COUNT(i.incident_id) = 0
ORDER BY ta.sophistication_tier DESC;


SELECT 
    t.tool_id,
    t.tool_name,
    t.tool_type,
    t.is_commodity,
    COUNT(i.incident_id) as times_used,
    CASE 
        WHEN COUNT(i.incident_id) = 0 THEN 'NEVER DEPLOYED'
        WHEN COUNT(i.incident_id) <= 2 THEN 'RARELY USED'
        ELSE 'ACTIVELY USED'
    END as usage_status
FROM incidents i
FULL JOIN tools t ON i.tool_id = t.tool_id
GROUP BY t.tool_id, t.tool_name, t.tool_type, t.is_commodity
ORDER BY times_used ASC, t.tool_name;


SELECT 
    COALESCE(ta.actor_name, 'NO ACTOR') as threat_actor,
    COALESCE(t.tool_name, 'NO TOOL') as tool_used,
    COUNT(i.incident_id) as collaboration_count,
    CASE 
        WHEN ta.actor_name IS NULL THEN 'TOOL WITHOUT ACTOR'
        WHEN t.tool_name IS NULL THEN 'ACTOR WITHOUT TOOL'
        WHEN COUNT(i.incident_id) > 0 THEN 'ESTABLISHED PAIRING'
        ELSE 'POTENTIAL PAIRING'
    END as relationship_type
FROM threat_actors ta
FULL JOIN incidents i ON ta.actor_id = i.actor_id
FULL JOIN tools t ON i.tool_id = t.tool_id
GROUP BY ta.actor_name, t.tool_name
ORDER BY collaboration_count DESC, threat_actor, tool_used;


SELECT 
    a1.actor_name as actor_a,
    a2.actor_name as actor_b,
    a1.region,
    a1.sophistication_tier as tier_a,
    a2.sophistication_tier as tier_b,
    CASE 
        WHEN a1.sophistication_tier = a2.sophistication_tier THEN 'SAME TIER'
        ELSE 'DIFFERENT TIER'
    END as coordination_likelihood
FROM threat_actors a1
INNER JOIN threat_actors a2 ON a1.region = a2.region 
    AND a1.actor_id < a2.actor_id  
ORDER BY a1.region, coordination_likelihood;


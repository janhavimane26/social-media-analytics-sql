-- ==============================================================
-- SQL + GenAI Mini Project : Social Media Analytics
-- Dataset : Social_Media (MySQL)
-- ==============================================================
USE Social_Media;

-- ==============================================================
-- Q1. Most Active Users (Posts + Comments)
-- ==============================================================
-- Count posts and comments separately, then add them (avoids duplicate rows).
SELECT u.user_id,
       u.username,
       COALESCE(p.post_count, 0)    AS total_posts,
       COALESCE(c.comment_count, 0) AS total_comments,
       COALESCE(p.post_count, 0) + COALESCE(c.comment_count, 0) AS total_activity
FROM users u
LEFT JOIN (SELECT user_id, COUNT(*) AS post_count
           FROM posts GROUP BY user_id) p ON p.user_id = u.user_id
LEFT JOIN (SELECT user_id, COUNT(*) AS comment_count
           FROM comments GROUP BY user_id) c ON c.user_id = u.user_id
ORDER BY total_activity DESC, u.user_id
LIMIT 10;

-- Solution Summary --
-- whitney74 is the most active user (9 actions: 3 posts + 6 comments).
-- Next best users have only 6-7 actions, so activity is spread thin, with no heavy "power users".


-- ==============================================================
-- Q2. Most Liked Posts and Creators
-- ==============================================================
SELECT p.post_id,
       u.username AS creator,
       COUNT(l.like_id) AS total_likes
FROM posts p
JOIN users u ON u.user_id = p.user_id
LEFT JOIN likes l ON l.post_id = p.post_id
GROUP BY p.post_id, u.username
ORDER BY total_likes DESC, p.post_id
LIMIT 10;

-- Solution Summary --
-- Max likes on any post is 6 (3 posts tie: howebryan, ktaylor, turnermichelle).
-- 364 of 1,000 posts (36%) got zero likes, so only a few posts really go viral.


-- ==============================================================
-- Q3. Top 5 Countries by Average Engagement (likes per post)
-- ==============================================================
SELECT u.country,
       COUNT(DISTINCT p.post_id) AS total_posts,
       COUNT(l.like_id)          AS total_likes,
       ROUND(COUNT(l.like_id) / COUNT(DISTINCT p.post_id), 2) AS avg_likes_per_post
FROM users u
JOIN posts p ON p.user_id = u.user_id
LEFT JOIN likes l ON l.post_id = p.post_id
GROUP BY u.country
ORDER BY avg_likes_per_post DESC
LIMIT 5;

-- Solution Summary --
-- Mexico leads with 3.0 likes per post, then Malta and Bahrain (2.5 each).
-- Caution: these countries have only 2-4 posts, so the averages are not very reliable.


-- ==============================================================
-- Q4. Trending Hashtags (used in more than 20 posts)
-- ==============================================================
SELECT h.tag_name,
       COUNT(DISTINCT ph.post_id) AS posts_using_tag
FROM hashtags h
JOIN post_hashtags ph ON ph.hashtag_id = h.hashtag_id
GROUP BY h.hashtag_id, h.tag_name
HAVING COUNT(DISTINCT ph.post_id) > 20
ORDER BY posts_using_tag DESC;

-- Same query with a lower cut-off (>= 4 posts), because the above returns no rows:
SELECT h.tag_name,
       COUNT(DISTINCT ph.post_id) AS posts_using_tag
FROM hashtags h
JOIN post_hashtags ph ON ph.hashtag_id = h.hashtag_id
GROUP BY h.hashtag_id, h.tag_name
HAVING COUNT(DISTINCT ph.post_id) >= 4
ORDER BY posts_using_tag DESC;

-- Solution Summary --
-- No hashtag is used in more than 20 posts. The most-used tags appear in only 5 posts.
-- The data has 1,000 hashtags for 1,000 tag links, so usage is very spread out (no clear trend).
-- With a cut-off of 4+ posts, 19 hashtags qualify.


-- ==============================================================
-- Q5. Top Influencers (Most Followers)
-- ==============================================================
SELECT u.user_id,
       u.username,
       COUNT(DISTINCT f.follower_user_id) AS follower_count
FROM users u
JOIN followers f ON f.user_id = u.user_id
GROUP BY u.user_id, u.username
ORDER BY follower_count DESC, u.username
LIMIT 10;

-- Solution Summary --
-- vthomas is the top influencer with 6 followers, followed by christy26 and corey63 (5 each).
-- The rest of the top 10 have 4 each, so influence is low and fairly even.


-- ==============================================================
-- Q6. Followers Who Never Interacted
-- ==============================================================
-- Users who follow someone but have no likes and no comments.
SELECT u.user_id, u.username
FROM users u
WHERE EXISTS     (SELECT 1 FROM followers f WHERE f.follower_user_id = u.user_id)
  AND NOT EXISTS (SELECT 1 FROM likes l      WHERE l.user_id = u.user_id)
  AND NOT EXISTS (SELECT 1 FROM comments c   WHERE c.user_id = u.user_id);

-- Solution Summary --
-- 85 users follow others but have never liked or commented.
-- These are "silent followers": a good target for re-engagement campaigns.


-- ==============================================================
-- Q7. Hashtags with Highest Engagement (likes + comments)
-- ==============================================================
-- Likes and comments are counted per post first, so rows are not multiplied.
SELECT h.tag_name,
       COALESCE(SUM(pl.like_count), 0)    AS total_likes,
       COALESCE(SUM(pc.comment_count), 0) AS total_comments,
       COALESCE(SUM(pl.like_count), 0) + COALESCE(SUM(pc.comment_count), 0) AS engagement_score
FROM hashtags h
JOIN post_hashtags ph ON ph.hashtag_id = h.hashtag_id
LEFT JOIN (SELECT post_id, COUNT(*) AS like_count
           FROM likes GROUP BY post_id) pl ON pl.post_id = ph.post_id
LEFT JOIN (SELECT post_id, COUNT(*) AS comment_count
           FROM comments GROUP BY post_id) pc ON pc.post_id = ph.post_id
GROUP BY h.hashtag_id, h.tag_name
ORDER BY engagement_score DESC, h.tag_name
LIMIT 10;

-- Solution Summary --
-- #population is the top hashtag (13 engagements), then #oil and #prove (12 each).
-- Gaps between the top 10 tags are small (10-13), so no single tag clearly dominates.


-- ==============================================================
-- Q8. Busiest Posting Hours and Days
-- ==============================================================
-- By hour
SELECT HOUR(created_at) AS post_hour,
       COUNT(*)         AS total_posts
FROM posts
GROUP BY HOUR(created_at)
ORDER BY total_posts DESC
LIMIT 5;

-- By weekday
SELECT DAYNAME(created_at) AS weekday,
       COUNT(*)            AS total_posts
FROM posts
GROUP BY DAYNAME(created_at), DAYOFWEEK(created_at)
ORDER BY total_posts DESC;

-- Solution Summary --
-- Busiest hour: 5 AM (54 posts), then 3 AM (53) and 10 PM (52).
-- Busiest day: Tuesday (153 posts); quietest: Sunday (132). Posting is fairly even across the week.


-- ==============================================================
-- Q9. Inactive Users (no posts, likes, or comments)
-- ==============================================================
SELECT u.user_id, u.username, u.country
FROM users u
LEFT JOIN posts    p ON p.user_id = u.user_id
LEFT JOIN likes    l ON l.user_id = u.user_id
LEFT JOIN comments c ON c.user_id = u.user_id
WHERE p.post_id IS NULL
  AND l.like_id IS NULL
  AND c.comment_id IS NULL;

-- Solution Summary --
-- 47 of 1,000 users (4.7%) have never posted, liked, or commented.
-- A small group, but worth a welcome / "get started" email.


-- ==============================================================
-- Q10. Top 5 Countries with Most Influencers
-- ==============================================================
-- Influencer = user with 4 or more followers (the top 20 users in this data).
SELECT u.country,
       COUNT(*) AS influencer_count
FROM users u
JOIN (SELECT user_id
      FROM followers
      GROUP BY user_id
      HAVING COUNT(*) >= 4) i ON i.user_id = u.user_id
GROUP BY u.country
ORDER BY influencer_count DESC, u.country
LIMIT 5;

-- Solution Summary --
-- Seychelles has the most influencers (2); every other country has just 1.
-- Influencers are spread across many countries, so there is no influencer hub.


-- ==============================================================
-- BONUS CHALLENGES
-- ==============================================================

-- B1. Engagement rate per user = (likes + comments) / posts
SELECT u.username,
       COUNT(DISTINCT p.post_id)    AS total_posts,
       COUNT(DISTINCT l.like_id)    AS total_likes,
       COUNT(DISTINCT c.comment_id) AS total_comments,
       ROUND((COUNT(DISTINCT l.like_id) + COUNT(DISTINCT c.comment_id))
             / COUNT(DISTINCT p.post_id), 2) AS engagement_rate
FROM users u
JOIN posts p ON p.user_id = u.user_id
LEFT JOIN likes l    ON l.post_id = p.post_id
LEFT JOIN comments c ON c.post_id = p.post_id
GROUP BY u.user_id, u.username
ORDER BY engagement_rate DESC, total_posts DESC
LIMIT 5;
-- Summary: turnermichelle has the best rate (8 engagements on 1 post), then ktaylor (7).

-- B2. Mutual followers (A follows B and B follows A)
SELECT a.user_id AS user_a, a.follower_user_id AS user_b
FROM followers a
JOIN followers b ON a.user_id = b.follower_user_id
                AND a.follower_user_id = b.user_id
WHERE a.user_id < a.follower_user_id;
-- Summary: only 1 mutual follower pair exists, so following is almost always one-way.


-- ==============================================================
-- REFLECTION
-- ==============================================================
-- 1. GenAI helped by writing first drafts of joins and explaining why a join duplicates rows.
-- 2. Optimization tip: count likes/comments in separate subqueries before joining, to avoid
--    duplicate rows; use NOT EXISTS for "never did X" checks.
-- 3. Business insight: engagement is low and evenly spread (36% of posts have no likes),
--    so re-engaging silent and inactive users is the biggest opportunity.

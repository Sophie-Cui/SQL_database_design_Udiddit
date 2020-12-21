CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(25) UNIQUE NOT NULL,
    user_login TIMESTAMP
);


CREATE TABLE topics (
    id SERIAL PRIMARY KEY,
    name VARCHAR(30) UNIQUE NOT NULL CHECK ((LENGTH(TRIM (name)) > 0)),
    description VARCHAR(500)
);

CREATE TABLE posts (
    id SERIAL PRIMARY KEY,
    title VARCHAR(100) NOT NULL UNIQUE CHECK ((LENGTH(TRIM(title)) > 0)),
    topic_id INTEGER REFERENCES topics (id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users (id) ON DELETE SET NULL,
    url VARCHAR DEFAULT NULL,
    text_context TEXT DEFAULT NULL,
    post_time TIMESTAMP,
    CONSTRAINT url_text_only_one_null
    CHECK ((url IS NULL AND text_context IS NOT NULL) OR (url IS NOT NULL AND text_context IS NULL))
);

CREATE INDEX find_posts_by_url ON posts (url);
CREATE INDEX find_post_by_topics ON posts (topic_id, post_time);
CREATE INDEX find_post_by_users ON posts (user_id, post_time);


CREATE TABLE comments (
    id SERIAL PRIMARY KEY,
    comment_context TEXT NOT NULL ,
    parent_comment_id INTEGER REFERENCES comments (id) ON DELETE CASCADE,
    post_id INTEGER REFERENCES posts (id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users (id) ON DELETE SET NULL,
    comment_time TIMESTAMP,
    CONSTRAINT comment_fk FOREIGN KEY (parent_comment_id)
    REFERENCES comments (id)
);

CREATE INDEX find_comments_by_users ON comments (user_id, comment_time);

CREATE TABLE votes (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users (id) ON DELETE SET NULL,
    post_id INTEGER REFERENCES posts (id) ON DELETE CASCADE,
    vote SMALLINT CHECK (vote = 1 OR vote = -1),
    UNIQUE (user_id, post_id)
);


INSERT INTO users (username)
SELECT DISTINCT username
FROM
( SELECT DISTINCT username FROM bad_comments
    UNION
    SELECT DISTINCT username FROM bad_posts
UNION
SELECT DISTINCT REGEXP_SPLIT_TO_TABLE(upvotes, ',') username FROM bad_posts
UNION
SELECT DISTINCT REGEXP_SPLIT_TO_TABLE(downvotes, ',') username FROM bad_posts
) tt;

INSERT INTO topics (name)
SELECT DISTINCT topic
FROM bad_posts;

INSERT INTO posts (title, topic_id, user_id, url, text_context)
SELECT LEFT(bp.title, 100) , t.id, u.id, bp.url, bp.text_content
FROM bad_posts bp
JOIN users u
ON bp.username = u.username
JOIN topics t
ON bp.topic = t.name;

INSERT INTO votes (user_id, post_id, vote)
SELECT user_id, post_id, vote FROM
(SELECT u.id user_id, t1.id post_id, 1 vote
FROM (SELECT id, REGEXP_SPLIT_TO_TABLE(upvotes, ',') username
            FROM bad_posts) t1
JOIN users u
ON t1.username = u.username
UNION
SELECT u.id user_id, t1.id post_id, -1 vote
FROM (SELECT id, REGEXP_SPLIT_TO_TABLE(downvotes, ',') username
            FROM bad_posts) t1
JOIN users u
ON t1.username = u.username) tt
;


INSERT INTO comments (comment_context, post_id, user_id)
SELECT bc.text_content, bc.post_id, u.id user_id
FROM bad_comments bc
JOIN users u
ON u.username = bc.username;

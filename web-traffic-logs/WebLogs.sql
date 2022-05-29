REVOKE ALL ON wlogs FROM wlogger;
DROP ROLE IF EXISTS wlogger;
CREATE USER wlogger ENCRYPTED PASSWORD 'WebLogger-Password'; -- TODO CHANGE_ME

REVOKE ALL ON wlogs FROM wlogreader;
DROP ROLE IF EXISTS wlogreader;
CREATE USER wlogreader ENCRYPTED PASSWORD 'wLogReader-Password'; -- TODO CHANGE_ME


DROP TABLE IF EXISTS wlogs;
CREATE TABLE wlogs (
  created_at TIMESTAMPTZ NOT NULL,
  ip INET NOT NULL,
  domain_name TEXT,
  uri TEXT NOT NULL,
  status INT NOT NULL,
  body_bytes INT NOT NULL,
  referer TEXT,
  ua TEXT,
  server TEXT NOT NULL,
  method TEXT NOT NULL
);
CREATE INDEX created_at_idx ON wlogs (created_at);


CREATE OR REPLACE PROCEDURE insert_log(created_at FLOAT, ip INET, domain_name TEXT, method TEXT, uri TEXT, status INT, body_bytes INT, referer TEXT, ua TEXT, server TEXT)
LANGUAGE SQL AS $$
	INSERT INTO wlogs VALUES (to_timestamp(created_at), ip, domain_name, uri, status, body_bytes, referer, ua, server, method);
$$;
-- CALL insert_log(1608427225.999, '1.2.3.4', 'blog.uidrafter.com', 'GET', 'myblogpost', 200, 1024, NULL, NULL, 0);


GRANT INSERT ON wlogs TO wlogger;
GRANT SELECT ON wlogs TO wlogreader;



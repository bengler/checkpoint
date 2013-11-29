--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: access_group_memberships; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE access_group_memberships (
    id integer NOT NULL,
    access_group_id integer NOT NULL,
    identity_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: access_group_memberships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE access_group_memberships_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: access_group_memberships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE access_group_memberships_id_seq OWNED BY access_group_memberships.id;


--
-- Name: access_group_subtrees; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE access_group_subtrees (
    id integer NOT NULL,
    access_group_id integer NOT NULL,
    location text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: access_group_subtrees_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE access_group_subtrees_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: access_group_subtrees_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE access_group_subtrees_id_seq OWNED BY access_group_subtrees.id;


--
-- Name: access_groups; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE access_groups (
    id integer NOT NULL,
    realm_id integer NOT NULL,
    label text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: access_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE access_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: access_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE access_groups_id_seq OWNED BY access_groups.id;


--
-- Name: accounts; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE accounts (
    id integer NOT NULL,
    identity_id integer,
    realm_id integer NOT NULL,
    provider text NOT NULL,
    uid text NOT NULL,
    token text,
    secret text,
    nickname text,
    name text,
    location text,
    description text,
    profile_url text,
    image_url text,
    email text,
    synced_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    phone text
);


--
-- Name: accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE accounts_id_seq OWNED BY accounts.id;


--
-- Name: bannings; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE bannings (
    id integer NOT NULL,
    fingerprint text,
    path text,
    location_id integer,
    realm_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: bannings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE bannings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bannings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE bannings_id_seq OWNED BY bannings.id;


--
-- Name: callbacks; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE callbacks (
    id integer NOT NULL,
    url text NOT NULL,
    path text NOT NULL,
    location_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: callbacks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE callbacks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: callbacks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE callbacks_id_seq OWNED BY callbacks.id;


--
-- Name: domains; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE domains (
    id integer NOT NULL,
    name text,
    realm_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    origins text
);


--
-- Name: domains_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE domains_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: domains_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE domains_id_seq OWNED BY domains.id;


--
-- Name: identities; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE identities (
    id integer NOT NULL,
    realm_id integer NOT NULL,
    primary_account_id integer,
    god boolean DEFAULT false,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    last_seen_on date
);


--
-- Name: identities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE identities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: identities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE identities_id_seq OWNED BY identities.id;


--
-- Name: identity_fingerprints; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE identity_fingerprints (
    id integer NOT NULL,
    identity_id integer NOT NULL,
    fingerprint text NOT NULL
);


--
-- Name: identity_fingerprints_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE identity_fingerprints_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: identity_fingerprints_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE identity_fingerprints_id_seq OWNED BY identity_fingerprints.id;


--
-- Name: identity_ips; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE identity_ips (
    id integer NOT NULL,
    address text NOT NULL,
    identity_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: identity_ips_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE identity_ips_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: identity_ips_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE identity_ips_id_seq OWNED BY identity_ips.id;


--
-- Name: identity_tags; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE identity_tags (
    id integer NOT NULL,
    identity_id integer NOT NULL,
    tag text NOT NULL
);


--
-- Name: identity_tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE identity_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: identity_tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE identity_tags_id_seq OWNED BY identity_tags.id;


--
-- Name: locations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE locations (
    id integer NOT NULL,
    label_0 text,
    label_1 text,
    label_2 text,
    label_3 text,
    label_4 text,
    label_5 text,
    label_6 text,
    label_7 text,
    label_8 text,
    label_9 text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: locations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE locations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: locations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE locations_id_seq OWNED BY locations.id;


--
-- Name: realms; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE realms (
    id integer NOT NULL,
    title text,
    label text NOT NULL,
    service_keys text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    primary_domain_id integer
);


--
-- Name: realms_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE realms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: realms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE realms_id_seq OWNED BY realms.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE sessions (
    id integer NOT NULL,
    identity_id integer,
    key text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sessions_id_seq OWNED BY sessions.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY access_group_memberships ALTER COLUMN id SET DEFAULT nextval('access_group_memberships_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY access_group_subtrees ALTER COLUMN id SET DEFAULT nextval('access_group_subtrees_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY access_groups ALTER COLUMN id SET DEFAULT nextval('access_groups_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY accounts ALTER COLUMN id SET DEFAULT nextval('accounts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY bannings ALTER COLUMN id SET DEFAULT nextval('bannings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY callbacks ALTER COLUMN id SET DEFAULT nextval('callbacks_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY domains ALTER COLUMN id SET DEFAULT nextval('domains_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY identities ALTER COLUMN id SET DEFAULT nextval('identities_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY identity_fingerprints ALTER COLUMN id SET DEFAULT nextval('identity_fingerprints_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY identity_ips ALTER COLUMN id SET DEFAULT nextval('identity_ips_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY identity_tags ALTER COLUMN id SET DEFAULT nextval('identity_tags_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY locations ALTER COLUMN id SET DEFAULT nextval('locations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY realms ALTER COLUMN id SET DEFAULT nextval('realms_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY sessions ALTER COLUMN id SET DEFAULT nextval('sessions_id_seq'::regclass);


--
-- Name: accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (id);


--
-- Name: bannings_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bannings
    ADD CONSTRAINT bannings_pkey PRIMARY KEY (id);


--
-- Name: callbacks_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY callbacks
    ADD CONSTRAINT callbacks_pkey PRIMARY KEY (id);


--
-- Name: domains_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY domains
    ADD CONSTRAINT domains_pkey PRIMARY KEY (id);


--
-- Name: group_memberships_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY access_group_memberships
    ADD CONSTRAINT group_memberships_pkey PRIMARY KEY (id);


--
-- Name: group_subtrees_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY access_group_subtrees
    ADD CONSTRAINT group_subtrees_pkey PRIMARY KEY (id);


--
-- Name: groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY access_groups
    ADD CONSTRAINT groups_pkey PRIMARY KEY (id);


--
-- Name: identities_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY identities
    ADD CONSTRAINT identities_pkey PRIMARY KEY (id);


--
-- Name: identity_fingerprints_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY identity_fingerprints
    ADD CONSTRAINT identity_fingerprints_pkey PRIMARY KEY (id);


--
-- Name: identity_ips_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY identity_ips
    ADD CONSTRAINT identity_ips_pkey PRIMARY KEY (id);


--
-- Name: identity_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY identity_tags
    ADD CONSTRAINT identity_tags_pkey PRIMARY KEY (id);


--
-- Name: locations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY locations
    ADD CONSTRAINT locations_pkey PRIMARY KEY (id);


--
-- Name: realms_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY realms
    ADD CONSTRAINT realms_pkey PRIMARY KEY (id);


--
-- Name: sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: account_uniqueness_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX account_uniqueness_index ON accounts USING btree (provider, realm_id, uid);


--
-- Name: group_label_uniqueness_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX group_label_uniqueness_index ON access_groups USING btree (realm_id, label);


--
-- Name: group_membership_identity_uniqueness_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX group_membership_identity_uniqueness_index ON access_group_memberships USING btree (access_group_id, identity_id);


--
-- Name: group_subtree_location_uniqueness_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX group_subtree_location_uniqueness_index ON access_group_subtrees USING btree (access_group_id, location);


--
-- Name: index_accounts_on_identity_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_accounts_on_identity_id ON accounts USING btree (identity_id);


--
-- Name: index_accounts_on_realm_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_accounts_on_realm_id ON accounts USING btree (realm_id);


--
-- Name: index_bannings_on_fingerprint_and_path; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_bannings_on_fingerprint_and_path ON bannings USING btree (fingerprint, path);


--
-- Name: index_callbacks_on_location_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_callbacks_on_location_id ON callbacks USING btree (location_id);


--
-- Name: index_domains_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_domains_on_name ON domains USING btree (name);


--
-- Name: index_domains_on_realm_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_domains_on_realm_id ON domains USING btree (realm_id);


--
-- Name: index_group_subtrees_on_group_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_group_subtrees_on_group_id ON access_group_subtrees USING btree (access_group_id);


--
-- Name: index_groups_on_realm_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_groups_on_realm_id ON access_groups USING btree (realm_id);


--
-- Name: index_identities_on_realm_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_identities_on_realm_id ON identities USING btree (realm_id);


--
-- Name: index_identity_fingerprints_on_fingerprint; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_identity_fingerprints_on_fingerprint ON identity_fingerprints USING btree (fingerprint);


--
-- Name: index_identity_fingerprints_on_identity_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_identity_fingerprints_on_identity_id ON identity_fingerprints USING btree (identity_id);


--
-- Name: index_identity_ips_on_address; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_identity_ips_on_address ON identity_ips USING btree (address);


--
-- Name: index_identity_ips_on_identity_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_identity_ips_on_identity_id ON identity_ips USING btree (identity_id);


--
-- Name: index_identity_tags_on_identity_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_identity_tags_on_identity_id ON identity_tags USING btree (identity_id);


--
-- Name: index_identity_tags_on_tag; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_identity_tags_on_tag ON identity_tags USING btree (tag);


--
-- Name: index_location_on_labels; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_location_on_labels ON locations USING btree (label_0, label_1, label_2, label_3, label_4, label_5, label_6, label_7, label_8, label_9);


--
-- Name: index_realms_on_label; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_realms_on_label ON realms USING btree (label);


--
-- Name: index_sessions_on_identity_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_sessions_on_identity_id ON sessions USING btree (identity_id);


--
-- Name: index_sessions_on_key; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_sessions_on_key ON sessions USING btree (key);


--
-- Name: session_key_uniqueness_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX session_key_uniqueness_index ON sessions USING btree (key);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: accounts_identity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY accounts
    ADD CONSTRAINT accounts_identity_id_fkey FOREIGN KEY (identity_id) REFERENCES identities(id);


--
-- Name: accounts_realm_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY accounts
    ADD CONSTRAINT accounts_realm_id_fkey FOREIGN KEY (realm_id) REFERENCES realms(id);


--
-- Name: domains_realm_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY domains
    ADD CONSTRAINT domains_realm_id_fkey FOREIGN KEY (realm_id) REFERENCES realms(id);


--
-- Name: group_memberships_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY access_group_memberships
    ADD CONSTRAINT group_memberships_group_id_fkey FOREIGN KEY (access_group_id) REFERENCES access_groups(id);


--
-- Name: group_memberships_identity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY access_group_memberships
    ADD CONSTRAINT group_memberships_identity_id_fkey FOREIGN KEY (identity_id) REFERENCES identities(id);


--
-- Name: group_subtrees_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY access_group_subtrees
    ADD CONSTRAINT group_subtrees_group_id_fkey FOREIGN KEY (access_group_id) REFERENCES access_groups(id);


--
-- Name: groups_realm_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY access_groups
    ADD CONSTRAINT groups_realm_id_fkey FOREIGN KEY (realm_id) REFERENCES realms(id);


--
-- Name: realms_primary_domain_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY realms
    ADD CONSTRAINT realms_primary_domain_id_fkey FOREIGN KEY (primary_domain_id) REFERENCES domains(id);


--
-- Name: sessions_identity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sessions
    ADD CONSTRAINT sessions_identity_id_fkey FOREIGN KEY (identity_id) REFERENCES identities(id);


--
-- PostgreSQL database dump complete
--


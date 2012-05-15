--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: accounts; Type: TABLE; Schema: public; Owner: checkpoint; Tablespace: 
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
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.accounts OWNER TO checkpoint;

--
-- Name: accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: checkpoint
--

CREATE SEQUENCE accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.accounts_id_seq OWNER TO checkpoint;

--
-- Name: accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: checkpoint
--

ALTER SEQUENCE accounts_id_seq OWNED BY accounts.id;


--
-- Name: domains; Type: TABLE; Schema: public; Owner: checkpoint; Tablespace: 
--

CREATE TABLE domains (
    id integer NOT NULL,
    name text,
    realm_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.domains OWNER TO checkpoint;

--
-- Name: domains_id_seq; Type: SEQUENCE; Schema: public; Owner: checkpoint
--

CREATE SEQUENCE domains_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.domains_id_seq OWNER TO checkpoint;

--
-- Name: domains_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: checkpoint
--

ALTER SEQUENCE domains_id_seq OWNED BY domains.id;


--
-- Name: identities; Type: TABLE; Schema: public; Owner: checkpoint; Tablespace: 
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


ALTER TABLE public.identities OWNER TO checkpoint;

--
-- Name: identities_id_seq; Type: SEQUENCE; Schema: public; Owner: checkpoint
--

CREATE SEQUENCE identities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.identities_id_seq OWNER TO checkpoint;

--
-- Name: identities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: checkpoint
--

ALTER SEQUENCE identities_id_seq OWNED BY identities.id;


--
-- Name: realms; Type: TABLE; Schema: public; Owner: checkpoint; Tablespace: 
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


ALTER TABLE public.realms OWNER TO checkpoint;

--
-- Name: realms_id_seq; Type: SEQUENCE; Schema: public; Owner: checkpoint
--

CREATE SEQUENCE realms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.realms_id_seq OWNER TO checkpoint;

--
-- Name: realms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: checkpoint
--

ALTER SEQUENCE realms_id_seq OWNED BY realms.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: checkpoint; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


ALTER TABLE public.schema_migrations OWNER TO checkpoint;

--
-- Name: sessions; Type: TABLE; Schema: public; Owner: checkpoint; Tablespace: 
--

CREATE TABLE sessions (
    id integer NOT NULL,
    identity_id integer,
    key text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    variables text
);


ALTER TABLE public.sessions OWNER TO checkpoint;

--
-- Name: sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: checkpoint
--

CREATE SEQUENCE sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sessions_id_seq OWNER TO checkpoint;

--
-- Name: sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: checkpoint
--

ALTER SEQUENCE sessions_id_seq OWNED BY sessions.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: checkpoint
--

ALTER TABLE ONLY accounts ALTER COLUMN id SET DEFAULT nextval('accounts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: checkpoint
--

ALTER TABLE ONLY domains ALTER COLUMN id SET DEFAULT nextval('domains_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: checkpoint
--

ALTER TABLE ONLY identities ALTER COLUMN id SET DEFAULT nextval('identities_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: checkpoint
--

ALTER TABLE ONLY realms ALTER COLUMN id SET DEFAULT nextval('realms_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: checkpoint
--

ALTER TABLE ONLY sessions ALTER COLUMN id SET DEFAULT nextval('sessions_id_seq'::regclass);


--
-- Name: accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: checkpoint; Tablespace: 
--

ALTER TABLE ONLY accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (id);


--
-- Name: domains_pkey; Type: CONSTRAINT; Schema: public; Owner: checkpoint; Tablespace: 
--

ALTER TABLE ONLY domains
    ADD CONSTRAINT domains_pkey PRIMARY KEY (id);


--
-- Name: identities_pkey; Type: CONSTRAINT; Schema: public; Owner: checkpoint; Tablespace: 
--

ALTER TABLE ONLY identities
    ADD CONSTRAINT identities_pkey PRIMARY KEY (id);


--
-- Name: realms_pkey; Type: CONSTRAINT; Schema: public; Owner: checkpoint; Tablespace: 
--

ALTER TABLE ONLY realms
    ADD CONSTRAINT realms_pkey PRIMARY KEY (id);


--
-- Name: sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: checkpoint; Tablespace: 
--

ALTER TABLE ONLY sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: account_uniqueness_index; Type: INDEX; Schema: public; Owner: checkpoint; Tablespace: 
--

CREATE UNIQUE INDEX account_uniqueness_index ON accounts USING btree (provider, identity_id, uid);


--
-- Name: index_accounts_on_identity_id; Type: INDEX; Schema: public; Owner: checkpoint; Tablespace: 
--

CREATE INDEX index_accounts_on_identity_id ON accounts USING btree (identity_id);


--
-- Name: index_accounts_on_realm_id; Type: INDEX; Schema: public; Owner: checkpoint; Tablespace: 
--

CREATE INDEX index_accounts_on_realm_id ON accounts USING btree (realm_id);


--
-- Name: index_domains_on_name; Type: INDEX; Schema: public; Owner: checkpoint; Tablespace: 
--

CREATE UNIQUE INDEX index_domains_on_name ON domains USING btree (name);


--
-- Name: index_domains_on_realm_id; Type: INDEX; Schema: public; Owner: checkpoint; Tablespace: 
--

CREATE INDEX index_domains_on_realm_id ON domains USING btree (realm_id);


--
-- Name: index_identities_on_realm_id; Type: INDEX; Schema: public; Owner: checkpoint; Tablespace: 
--

CREATE INDEX index_identities_on_realm_id ON identities USING btree (realm_id);


--
-- Name: index_realms_on_label; Type: INDEX; Schema: public; Owner: checkpoint; Tablespace: 
--

CREATE UNIQUE INDEX index_realms_on_label ON realms USING btree (label);


--
-- Name: index_sessions_on_key; Type: INDEX; Schema: public; Owner: checkpoint; Tablespace: 
--

CREATE INDEX index_sessions_on_key ON sessions USING btree (key);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: checkpoint; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: accounts_identity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: checkpoint
--

ALTER TABLE ONLY accounts
    ADD CONSTRAINT accounts_identity_id_fkey FOREIGN KEY (identity_id) REFERENCES identities(id);


--
-- Name: accounts_realm_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: checkpoint
--

ALTER TABLE ONLY accounts
    ADD CONSTRAINT accounts_realm_id_fkey FOREIGN KEY (realm_id) REFERENCES realms(id);


--
-- Name: domains_realm_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: checkpoint
--

ALTER TABLE ONLY domains
    ADD CONSTRAINT domains_realm_id_fkey FOREIGN KEY (realm_id) REFERENCES realms(id);


--
-- Name: realms_primary_domain_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: checkpoint
--

ALTER TABLE ONLY realms
    ADD CONSTRAINT realms_primary_domain_id_fkey FOREIGN KEY (primary_domain_id) REFERENCES domains(id);


--
-- Name: sessions_identity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: checkpoint
--

ALTER TABLE ONLY sessions
    ADD CONSTRAINT sessions_identity_id_fkey FOREIGN KEY (identity_id) REFERENCES identities(id);


--
-- PostgreSQL database dump complete
--


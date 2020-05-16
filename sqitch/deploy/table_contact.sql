-- Deploy maevsi:table_contact to pg
-- requires: schema_public
-- requires: role_account
-- requires: role_anonymous
-- requires: function_invites_contact
-- requires: function_regexp_escape

BEGIN;

CREATE TABLE maevsi.contact (
    "id"                            SERIAL PRIMARY KEY,
    "first_name"                    TEXT CHECK (char_length("first_name") < 100),
    "last_name"                     TEXT CHECK (char_length("last_name") < 100),
    "address"                       TEXT CHECK (char_length("address") < 300),
    "email_address"                 TEXT CHECK (char_length("email_address") < 320 AND "email_address" ~* '^.+@.+\..+$'),
    "email_address_hash"            TEXT GENERATED ALWAYS AS (md5(lower(substring("email_address", '\S(?:.*\S)*')))) STORED,
    "profile_picture_storage_id"    TEXT CHECK ("profile_picture_storage_id" ~ '[0-9a-z]{32}')
    -- TODO: "website_url"           TEXT
);

COMMENT ON TABLE maevsi.contact IS 'Contact data.';
COMMENT ON COLUMN maevsi.contact.id IS 'The record''s id.';
COMMENT ON COLUMN maevsi.contact.first_name IS 'The contact''s first name.';
COMMENT ON COLUMN maevsi.contact.last_name IS 'The contact''s last name.';
COMMENT ON COLUMN maevsi.contact.address IS 'The contact''s physical address.';
COMMENT ON COLUMN maevsi.contact.email_address IS 'The contact''s e-mail address.';
COMMENT ON COLUMN maevsi.contact.email_address_hash IS 'The contact''s e-mail address''s md5 hash.';
COMMENT ON COLUMN maevsi.contact.profile_picture_storage_id IS 'The id under which the contact''s profile picture is stored.';

GRANT SELECT ON TABLE maevsi.contact TO maevsi_account, maevsi_anonymous;
GRANT INSERT, UPDATE, DELETE ON TABLE maevsi.contact TO maevsi_account;
GRANT USAGE ON SEQUENCE maevsi.contact_id_seq TO maevsi_account;

ALTER TABLE maevsi.contact ENABLE ROW LEVEL SECURITY;

-- Display the contact that is linked to the own account.
-- Display contacts that are accessible via contact invites.
CREATE POLICY contact_select ON maevsi.contact FOR SELECT USING (
        id = current_setting('jwt.claims.account_id', true)::INTEGER
    OR  id IN (SELECT maevsi_private.invites_contact())
);

COMMIT;

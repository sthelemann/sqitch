-- Deploy maevsi:function_invites to pg
-- requires: schema_public
-- requires: table_invite_account
-- requires: table_invite_contact

BEGIN;

CREATE FUNCTION maevsi_private.events_invited() RETURNS TABLE (event_id INTEGER) AS $$
BEGIN
    RETURN QUERY
    SELECT invite_account.event_id FROM maevsi.invite_account
    WHERE invite_account.username = current_setting('jwt.claims.username', true)::TEXT
    UNION ALL
    SELECT invite_contact.event_id FROM maevsi.invite_contact
    WHERE invite_contact.uuid = ANY (string_to_array(replace(btrim(current_setting('jwt.claims.invites', true), '[]'), '"', ''), ',')::UUID[]);
END
$$ LANGUAGE PLPGSQL STRICT SECURITY DEFINER;

COMMENT ON FUNCTION maevsi_private.events_invited() IS 'Add a function that returns all event ids for which the invoker is invited.';

GRANT EXECUTE ON FUNCTION maevsi_private.events_invited() TO maevsi_account, maevsi_anonymous;

COMMIT;

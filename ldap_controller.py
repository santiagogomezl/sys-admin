import ldap
import config.ldap_config as config
# def authenticate(address, username, password):

ldap_svr= config.LDAP_SERVER
ldap_usr= config.LDAP_USERNAME
ldap_pwd= config.LDAP_PASSWORD
base_dn = config.BASE_DN

"""
Tasks:
-Define OPT_REFERRALS for async calls
-Define search_filter
-for each group, remove username
"""

username = "stemmy"
search_filter = "(&(objectClass=user)(sAMAccountName=" + username + "))"


def authenticate(ldap_svr, ldap_usr, ldap_pwd):
    try:
        # build a client
        conn = ldap.initialize('ldap://' + ldap_svr)
        # perform a synchronous bind
        conn.set_option(ldap.OPT_REFERRALS,0)
        conn.simple_bind_s(ldap_usr, ldap_pwd)
        return conn
    except ldap.INVALID_CREDENTIALS:
        #print("wron")
        conn.unbind()
        #  return 'Wrong username or password'
    except ldap.SERVER_DOWN:
        #print("down")
        # return 'AD server not awailable'
    # all is well
    # get all user groups and store 
        print("Error")

def get_user_info(conn):
    #add try except block
    msgid = conn.search(base_dn, ldap.SCOPE_SUBTREE, search_filter)
    user_info = conn.result(msgid)
    return user_info

def remove_user_groups(conn, groups):
    for group in groups:
        search_filter = "(&(objectClass=group)(distinguishedName=" + group + "))"
        msgid = conn.search(base_dn, ldap.SCOPE_SUBTREE, search_filter)
        group_info = conn.result(msgid)
        print(group_info)


def close_connection():
    pass

if __name__ == "__main__":
    ldap_conn = authenticate(ldap_svr, ldap_usr, ldap_pwd) 
    user_info = get_user_info(ldap_conn) #user_info > (int,[str, (str,dict)])
    # print(user_info)
    user_groups = user_info[1][0][1]['memberOf'] # [bytes] b'string'
    print(user_groups)
    user_groups_str = [user_group.decode('utf-8') for user_group in user_groups]
    # remove_user_groups(ldap_conn, user_groups_str)

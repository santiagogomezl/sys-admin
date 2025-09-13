import ldap
import config.ldap_config as config
# def authenticate(address, username, password):

ldap_svr= config.LDAP_SERVER
ldap_usr= config.LDAP_USERNAME
ldap_pwd= config.LDAP_PASSWORD


def authenticate(ldap_svr, ldap_usr, ldap_pwd):
    try:
        # build a client
        conn = ldap.initialize('ldap://' + ldap_svr)
        # perform a synchronous bind
        conn.set_option(ldap.OPT_REFERRALS,0)
        conn.simple_bind_s(ldap_usr, ldap_pwd)
        print(conn)
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

# if __name__ == "__main__":
    authenticate(ldap_svr, ldap_usr, ldap_pwd) 

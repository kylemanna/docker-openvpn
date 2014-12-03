import cherrypy
from cherrypy.lib.static import serve_file
disabled = False
class ConfigServer(object):
    def download_profile(self):
        if disabled is True:
            return "This service has been disabled."
        else:
            return serve_file('/etc/openvpn/client.ovpn', "application/x-download", "attachment")
    download_profile.exposed = True
    def index(self):
        if disabled is True:
            return "This service has been disabled."
        else:
            return """
            <html>
              <p> To download your OpenVPN profile, click <a href="/download_profile">here</a>.
              <p> When you have finished downloading your OpenVPN profile, click <a href="/lockout">here</a> to disable this page and the download page.
            </html>
            """
    index.exposed = True
    def lockout(self):
        global disabled
        disabled = True
        return "The download page has been disabled."
    lockout.exposed = True

cherrypy.config.update({'engine.autoreload.on': False})
cherrypy.server.unsubscribe()
cherrypy.engine.start()

app = cherrypy.tree.mount(ConfigServer())

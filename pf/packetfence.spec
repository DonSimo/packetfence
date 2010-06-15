# PacketFence RPM SPEC
# DO NOT FORGET TO UPDATE CHANGELOG AT THE END OF THE FILE WHENEVER IT IS MODIFIED!
# 
# BUILDING FOR RELEASE
# 
# - Create release tarball from monotone head, ex:
# mtn --db ~/pf.mtn checkout --branch org.packetfence.1_8
# cd org.packetfence.1_8/
# tar czvf packetfence-1.8.5.tar.gz pf/
# 
# - Build
#  - define dist based on target distro (for centos/rhel => .el5)
#  - define source_release based on package revision (must be > 0 for proprer upgrade from snapshots)
# ex:
# cd /usr/src/redhat/
# rpmbuild -ba --define 'dist .el5' --define 'source_release 1' SPECS/packetfence.spec
#
#
# BUILDING FOR A SNAPSHOT (PRE-RELEASE)
#
# - Create release tarball from monotone head. Specify 0.<date> in tarball, ex:
# mtn --db ~/pf.mtn checkout --branch org.packetfence.1_8
# cd org.packetfence.1_8/
# tar czvf packetfence-1.8.5-0.20091023.tar.gz pf/
#
# - Build
#  - define snapshot 1
#  - define dist based on target distro (for centos/rhel => .el5)
#  - define source_release to 0.<date> this way one can upgrade from snapshot to release
# ex:
# cd /usr/src/redhat/
# rpmbuild -ba --define 'snapshot 1' --define 'dist .el5' --define 'source_release 0.20100506' SPECS/packetfence.spec
#
Summary: PacketFence network registration / worm mitigation system
Name: packetfence
Version: 1.9.0
Release: %{source_release}%{?dist}
License: GPL
Group: System Environment/Daemons
URL: http://www.packetfence.org
AutoReqProv: 0
BuildArch: noarch
BuildRoot: %{_tmppath}/%{name}-%{version}-%{source_release}-root

Packager: Inverse inc. <support@inverse.ca>
Vendor: PacketFence, http://www.packetfence.org

# if --define 'snapshot 1' not written when calling rpmbuild then we assume it is to package a release
%define is_release %{?snapshot:0}%{!?snapshot:1}
%if %{is_release}
# used for official releases
Source: http://prdownloads.sourceforge.net/packetfence/%{name}-%{version}.tar.gz
%else
# used for snapshot releases
Source: http://www.packetfence.org/downloads/%{name}-%{version}-%{source_release}.tar.gz
%endif

# FIXME change all perl Requires: into their namespace counterpart, see what happened in #931 and
# http://www.rpm.org/wiki/PackagerDocs/Dependencies#InterpretersandShells for discussion on why
BuildRequires: gettext, httpd
BuildRequires: perl(Parse::RecDescent)
Requires: chkconfig, coreutils, grep, iproute, openssl, sed, tar, wget
Requires: libpcap, libxml2, zlib, zlib-devel, glibc-common,
Requires: httpd, mod_ssl, php, php-gd
Requires: mod_perl
# php-pear-Log required not php-pear, fixes #804
Requires: php-pear-Log
Requires: net-tools
Requires: net-snmp >= 5.3.2.2
Requires: mysql, perl-DBD-mysql
Requires: perl >= 5.8.8, perl-suidperl
Requires: perl-Apache-Htpasswd
Requires: perl-Bit-Vector
Requires: perl-CGI-Session
Requires: perl-Class-Accessor
Requires: perl-Class-Accessor-Fast-Contained
Requires: perl-Class-Data-Inheritable
Requires: perl-Class-Gomor
Requires: perl-Config-IniFiles >= 2.40
Requires: perl-Data-Phrasebook, perl-Data-Phrasebook-Loader-YAML
Requires: perl-DBI
Requires: perl-File-Tail
Requires: perl-IPC-Cmd
Requires: perl-IPTables-ChainMgr
Requires: perl-IPTables-Parse
Requires: perl-LDAP
Requires: perl-libwww-perl
Requires: perl-List-MoreUtils
# Changed perl-Locale-gettext dependency to use the perl namespace version: perl(Locale-gettext), fixes #931
Requires: perl(Locale::gettext)
Requires: perl-Log-Log4perl >= 1.11
Requires: perl-Net-Appliance-Session
Requires: perl-Net-Frame, perl-Net-Frame-Simple
Requires: perl-Net-MAC, perl-Net-MAC-Vendor
Requires: perl-Net-Netmask
Requires: perl-Net-Pcap >= 0.16
Requires: perl-Net-SNMP
# for SNMPv3 AES as privacy protocol, fixes #775
Requires: perl-Crypt-Rijndael
Requires: perl-Net-Telnet
Requires: perl-Net-Write
Requires: perl-Parse-Nessus-NBE
Requires: perl(Parse::RecDescent)
# TODO: portability for non-x86 is questionnable for Readonly::XS
Requires: perl-Readonly, perl(Readonly::XS)
Requires: perl-Regexp-Common
Requires: rrdtool, perl-rrdtool
Requires: perl-SOAP-Lite
Requires: perl-Template-Toolkit
Requires: perl-TermReadKey
Requires: perl-Thread-Pool
Requires: perl-TimeDate
Requires: perl-UNIVERSAL-require
Requires: perl-YAML
Requires: php-jpgraph-packetfence = 2.3.4
Requires: php-ldap
Requires: perl(Try::Tiny)
# Required for testing
# TODO: I noticed that we provide perl-Test-MockDBI in our repo, maybe we made a poo poo with the deps
BuildRequires: perl(Test::MockModule), perl(Test::MockDBI), perl(Test::Perl::Critic)
BuildRequires: perl(Test::Pod), perl(Test::Pod::Coverage), perl(Test::Exception), perl(Test::NoWarnings)

%description

PacketFence is an open source network access control (NAC) system. 
It can be used to effectively secure networks, from small to very large 
heterogeneous networks. PacketFence provides features such 
as 
* registration of new network devices
* detection of abnormal network activities
* isolation of problematic devices
* remediation through a captive portal 
* registration-based and scheduled vulnerability scans.

%package remote-snort-sensor
Group: System Environment/Daemons
Requires: perl >= 5.8.0, snort, perl(File::Tail), perl(Config::IniFiles), perl(IO::Socket::SSL), perl(XML::Parser), perl(Crypt::SSLeay)
Requires: perl-SOAP-Lite
Requires: perl-LWP-UserAgent-Determined
Conflicts: packetfence
AutoReqProv: 0
Summary: Files needed for sending snort alerts to packetfence

%description remote-snort-sensor
The packetfence-remote-snort-sensor package contains the files needed
for sending snort alerts from a remote snort sensor to a PacketFence
server.

%prep
%setup -n pf

%build
# generate pfcmd_pregrammar
/usr/bin/perl -w -e 'use strict; use warnings; use diagnostics; use Parse::RecDescent; use lib "./lib"; use pf::pfcmd::pfcmd; Parse::RecDescent->Precompile($grammar, "pfcmd_pregrammar");'
mv pfcmd_pregrammar.pm lib/pf/pfcmd/

# generate translations
/usr/bin/msgfmt conf/locale/en/LC_MESSAGES/packetfence.po
mv packetfence.mo conf/locale/en/LC_MESSAGES/
/usr/bin/msgfmt conf/locale/es/LC_MESSAGES/packetfence.po
mv packetfence.mo conf/locale/es/LC_MESSAGES/
/usr/bin/msgfmt conf/locale/fr/LC_MESSAGES/packetfence.po
mv packetfence.mo conf/locale/fr/LC_MESSAGES/
/usr/bin/msgfmt conf/locale/it/LC_MESSAGES/packetfence.po
mv packetfence.mo conf/locale/it/LC_MESSAGES/
/usr/bin/msgfmt conf/locale/nl/LC_MESSAGES/packetfence.po
mv packetfence.mo conf/locale/nl/LC_MESSAGES/

%install
%{__rm} -rf $RPM_BUILD_ROOT
%{__install} -D -m0755 packetfence.init $RPM_BUILD_ROOT%{_initrddir}/packetfence
%{__install} -d $RPM_BUILD_ROOT/usr/local/pf
%{__install} -d $RPM_BUILD_ROOT/usr/local/pf/logs
%{__install} -d $RPM_BUILD_ROOT/usr/local/pf/var/session
%{__install} -d $RPM_BUILD_ROOT/usr/local/pf/var/rrd 
%{__install} -d $RPM_BUILD_ROOT/usr/local/pf/addons
cp -r bin $RPM_BUILD_ROOT/usr/local/pf/
cp -r addons/802.1X/ $RPM_BUILD_ROOT/usr/local/pf/addons/
cp -r addons/integration-testing/ $RPM_BUILD_ROOT/usr/local/pf/addons/
cp -r addons/high-availability/ $RPM_BUILD_ROOT/usr/local/pf/addons/
cp -r addons/mrtg/ $RPM_BUILD_ROOT/usr/local/pf/addons/
cp -r addons/snort/ $RPM_BUILD_ROOT/usr/local/pf/addons/
cp addons/*.pl $RPM_BUILD_ROOT/usr/local/pf/addons/
cp addons/*.sh $RPM_BUILD_ROOT/usr/local/pf/addons/
cp addons/logrotate $RPM_BUILD_ROOT/usr/local/pf/addons/
cp -r sbin $RPM_BUILD_ROOT/usr/local/pf/
cp -r cgi-bin $RPM_BUILD_ROOT/usr/local/pf/
cp -r conf $RPM_BUILD_ROOT/usr/local/pf/
#pfdetect_remote
mv addons/pfdetect_remote/initrd/pfdetectd $RPM_BUILD_ROOT%{_initrddir}/
mv addons/pfdetect_remote/sbin/pfdetect_remote $RPM_BUILD_ROOT/usr/local/pf/sbin
mv addons/pfdetect_remote/conf/pfdetect_remote.conf $RPM_BUILD_ROOT/usr/local/pf/conf
rmdir addons/pfdetect_remote/sbin
rmdir addons/pfdetect_remote/initrd
rmdir addons/pfdetect_remote/conf
rmdir addons/pfdetect_remote
#end pfdetect_remote
cp -r ChangeLog $RPM_BUILD_ROOT/usr/local/pf/
cp -r configurator.pl $RPM_BUILD_ROOT/usr/local/pf/
cp -r COPYING $RPM_BUILD_ROOT/usr/local/pf/
cp -r db $RPM_BUILD_ROOT/usr/local/pf/
cp -r docs $RPM_BUILD_ROOT/usr/local/pf/
cp -r html $RPM_BUILD_ROOT/usr/local/pf/
cp -r installer.pl $RPM_BUILD_ROOT/usr/local/pf/
cp -r lib $RPM_BUILD_ROOT/usr/local/pf/
cp -r NEWS $RPM_BUILD_ROOT/usr/local/pf/
cp -r README $RPM_BUILD_ROOT/usr/local/pf/
cp -r README_SWITCHES $RPM_BUILD_ROOT/usr/local/pf/
cp -r UPGRADE $RPM_BUILD_ROOT/usr/local/pf/
#cp -r t $RPM_BUILD_ROOT/usr/local/pf/
cp -r test $RPM_BUILD_ROOT/usr/local/pf/

#start create symlinks
curdir=`pwd`

#pfschema symlink
cd $RPM_BUILD_ROOT/usr/local/pf/db
ln -s pfschema.mysql.190 ./pfschema.mysql

#httpd.conf symlink
#TODO: isn't it stupid to decide what Apache version is there at rpm build time?
cd $RPM_BUILD_ROOT/usr/local/pf/conf/templates
if (/usr/sbin/httpd -v | egrep 'Apache/2\.[2-9]\.' > /dev/null)
then
  ln -s httpd.conf.apache22 ./httpd.conf
else
  ln -s httpd.conf.pre_apache22 ./httpd.conf
fi

cd $curdir
#end create symlinks


%pre

if ! /usr/bin/id pf &>/dev/null; then
	/usr/sbin/useradd -r -d "/usr/local/pf" -s /bin/sh -c "PacketFence" -M pf || \
		echo Unexpected error adding user "pf" && exit
fi

#if [ ! `tty | cut -c0-8` = "/dev/tty" ];
#then
#  echo You must be on a directly connected console to install this package!
#  exit
#fi

if [ ! `id -u` = "0" ];
then
  echo You must install this package as root!
  exit
fi

#if [ ! `cat /proc/modules | grep ^ip_tables|cut -f1 -d" "` = "ip_tables" ];
#then
#  echo Required module "ip_tables" does not appear to be loaded - now loading
#  /sbin/modprobe ip_tables
#fi


%pre remote-snort-sensor

if ! /usr/bin/id pf &>/dev/null; then
	/usr/sbin/useradd -r -d "/usr/local/pf" -s /bin/sh -c "PacketFence" -M pf || \
		echo Unexpected error adding user "pf" && exit
fi

%post
echo "Adding PacketFence startup script"
/sbin/chkconfig --add packetfence
for service in snortd httpd snmptrapd
do
  if /sbin/chkconfig --list | grep $service > /dev/null 2>&1; then
    echo "Disabling $service startup script"
    /sbin/chkconfig --del $service > /dev/null 2>&1
  fi
done

#touch /usr/local/pf/conf/dhcpd/dhcpd.leases && chown pf:pf /usr/local/pf/conf/dhcpd/dhcpd.leases

if [ -e /etc/logrotate.d/snort ]; then
  echo Removing /etc/logrotate.d/snort - it kills snort every night
  rm -f /etc/logrotate.d/snort
fi

if [ -d /usr/local/pf/html/user/content/docs ]; then
  echo Removing legacy docs directory
  rm -rf /usr/local/pf/html/user/content/docs
fi

echo Installation complete
#TODO: consider renaming installer.pl to setup.pl?
echo "  * Please cd /usr/local/pf && ./installer.pl to finish installation and configure PF"

%post remote-snort-sensor
echo "Adding PacketFence remote Snort Sensor startup script"
/sbin/chkconfig --add pfdetectd

%preun
if [ $1 -eq 0 ] ; then
	/sbin/service packetfence stop &>/dev/null || :
	/sbin/chkconfig --del packetfence
fi
#rm -f /usr/local/pf/conf/dhcpd/dhcpd.leases

%preun remote-snort-sensor
if [ $1 -eq 0 ] ; then
	/sbin/service pfdetectd stop &>/dev/null || :
	/sbin/chkconfig --del pfdetectd
fi

%postun
if [ $1 -eq 0 ]; then
	/usr/sbin/userdel pf || %logmsg "User \"pf\" could not be deleted."
#	/usr/sbin/groupdel pf || %logmsg "Group \"pf\" could not be deleted."
#else
#	/sbin/service pf condrestart &>/dev/null || :
fi

%postun remote-snort-sensor
if [ $1 -eq 0 ]; then
	/usr/sbin/userdel pf || %logmsg "User \"pf\" could not be deleted."
fi

%files

%defattr(-, pf, pf)
%attr(0755, root, root) %{_initrddir}/packetfence

%dir                    /usr/local/pf
%dir                    /usr/local/pf/addons
%attr(0755, pf, pf)     /usr/local/pf/addons/accounting.pl
%attr(0755, pf, pf)     /usr/local/pf/addons/autodiscover.pl
%attr(0755, pf, pf)     /usr/local/pf/addons/convertToPortSecurity.pl
%attr(0755, pf, pf)	/usr/local/pf/addons/database-backup-and-maintenance.sh
%dir                    /usr/local/pf/addons/high-availability/
                        /usr/local/pf/addons/high-availability/*
%dir                    /usr/local/pf/addons/integration-testing/
                        /usr/local/pf/addons/integration-testing/*
%attr(0755, pf, pf)     /usr/local/pf/addons/loadMACintoDB.pl
                        /usr/local/pf/addons/logrotate
%attr(0755, pf, pf)	/usr/local/pf/addons/migrate-to-locationlog_history.sh
%attr(0755, pf, pf)     /usr/local/pf/addons/monitorpfsetvlan.pl
%dir                    /usr/local/pf/addons/mrtg
                        /usr/local/pf/addons/mrtg/*
%attr(0755, pf, pf)     /usr/local/pf/addons/recovery.pl
%dir                    /usr/local/pf/addons/snort
                        /usr/local/pf/addons/snort/oinkmaster.conf
%dir                    /usr/local/pf/addons/802.1X
%doc                    /usr/local/pf/addons/802.1X/README
%attr(0755, pf, pf)     /usr/local/pf/addons/802.1X/rlm_perl_packetfence_sql.pl
%attr(0755, pf, pf)     /usr/local/pf/addons/802.1X/rlm_perl_packetfence_soap.pl
%dir                    /usr/local/pf/bin
%attr(0755, pf, pf)     /usr/local/pf/bin/flip.pl
%attr(6755, root, root) /usr/local/pf/bin/pfcmd
%attr(0755, pf, pf)     /usr/local/pf/bin/pfcmd_vlan
%dir                    /usr/local/pf/cgi-bin
%attr(0755, pf, pf)     /usr/local/pf/cgi-bin/pdp.cgi
%attr(0755, pf, pf)     /usr/local/pf/cgi-bin/redir.cgi
%attr(0755, pf, pf)     /usr/local/pf/cgi-bin/register.cgi
%attr(0755, pf, pf)     /usr/local/pf/cgi-bin/release.cgi
%doc                    /usr/local/pf/ChangeLog
%dir                    /usr/local/pf/conf
%config(noreplace)      /usr/local/pf/conf/admin_ldap.conf
%dir                    /usr/local/pf/conf/authentication
%config(noreplace)      /usr/local/pf/conf/authentication/local.pm
%config(noreplace)      /usr/local/pf/conf/authentication/ldap.pm
%config(noreplace)      /usr/local/pf/conf/authentication/radius.pm
%config                 /usr/local/pf/conf/dhcp_fingerprints.conf
%dir                    /usr/local/pf/conf/dhcpd
                        /usr/local/pf/conf/dhcpd/dhcpd.leases
%config                 /usr/local/pf/conf/documentation.conf
%config(noreplace)      /usr/local/pf/conf/floating_network_device.conf
%dir                    /usr/local/pf/conf/locale
%dir                    /usr/local/pf/conf/locale/en
%dir                    /usr/local/pf/conf/locale/en/LC_MESSAGES
%config(noreplace)      /usr/local/pf/conf/locale/en/LC_MESSAGES/packetfence.po
%config(noreplace)      /usr/local/pf/conf/locale/en/LC_MESSAGES/packetfence.mo
%dir                    /usr/local/pf/conf/locale/es
%dir                    /usr/local/pf/conf/locale/es/LC_MESSAGES
%config(noreplace)      /usr/local/pf/conf/locale/es/LC_MESSAGES/packetfence.po
%config(noreplace)      /usr/local/pf/conf/locale/es/LC_MESSAGES/packetfence.mo
%dir                    /usr/local/pf/conf/locale/fr
%dir                    /usr/local/pf/conf/locale/fr/LC_MESSAGES
%config(noreplace)      /usr/local/pf/conf/locale/fr/LC_MESSAGES/packetfence.po
%config(noreplace)      /usr/local/pf/conf/locale/fr/LC_MESSAGES/packetfence.mo
%dir                    /usr/local/pf/conf/locale/it
%dir                    /usr/local/pf/conf/locale/it/LC_MESSAGES
%config(noreplace)      /usr/local/pf/conf/locale/it/LC_MESSAGES/packetfence.po
%config(noreplace)      /usr/local/pf/conf/locale/it/LC_MESSAGES/packetfence.mo
%dir                    /usr/local/pf/conf/locale/nl
%dir                    /usr/local/pf/conf/locale/nl/LC_MESSAGES
%config(noreplace)      /usr/local/pf/conf/locale/nl/LC_MESSAGES/packetfence.po
%config(noreplace)      /usr/local/pf/conf/locale/nl/LC_MESSAGES/packetfence.mo
%config(noreplace)      /usr/local/pf/conf/log.conf
%dir                    /usr/local/pf/conf/named
%dir                    /usr/local/pf/conf/nessus
%config(noreplace)      /usr/local/pf/conf/nessus/remotescan.nessus
%config(noreplace)      /usr/local/pf/conf/networks.conf
%config                 /usr/local/pf/conf/oui.txt
#%config(noreplace)      /usr/local/pf/conf/pf.conf
%config                 /usr/local/pf/conf/pf.conf.defaults
                        /usr/local/pf/conf/pf-release
#%config                 /usr/local/pf/conf/services.conf
%dir                    /usr/local/pf/conf/snort
%config(noreplace)	/usr/local/pf/conf/snort/classification.config
%config(noreplace)	/usr/local/pf/conf/snort/local.rules
%config(noreplace)	/usr/local/pf/conf/snort/reference.config
%dir                    /usr/local/pf/conf/ssl
%config(noreplace)      /usr/local/pf/conf/switches.conf
%dir                    /usr/local/pf/conf/templates
%dir                    /usr/local/pf/conf/templates/configurator
                        /usr/local/pf/conf/templates/configurator/*
%config                 /usr/local/pf/conf/templates/dhcpd.conf
%config                 /usr/local/pf/conf/templates/dhcpd_vlan.conf
%config                 /usr/local/pf/conf/templates/httpd.conf
%config                 /usr/local/pf/conf/templates/httpd.conf.apache22
%config                 /usr/local/pf/conf/templates/httpd.conf.pre_apache22
%config(noreplace)      /usr/local/pf/conf/templates/iptables.conf
%config(noreplace)      /usr/local/pf/conf/templates/listener.msg
%config(noreplace)      /usr/local/pf/conf/templates/named-registration.ca
%config(noreplace)      /usr/local/pf/conf/templates/named-isolation.ca
%config                 /usr/local/pf/conf/templates/named_vlan.conf
%config(noreplace)      /usr/local/pf/conf/templates/popup.msg
%config(noreplace)      /usr/local/pf/conf/templates/snmptrapd.conf
%config(noreplace)	/usr/local/pf/conf/templates/snort.conf
%config(noreplace)	/usr/local/pf/conf/templates/snort.conf.pre_snort-2.8
%config			/usr/local/pf/conf/ui.conf
%config(noreplace)      /usr/local/pf/conf/ui-global.conf
%dir                    /usr/local/pf/conf/users
%config(noreplace)      /usr/local/pf/conf/violations.conf
%attr(0755, pf, pf)     /usr/local/pf/configurator.pl
%doc                    /usr/local/pf/COPYING
%dir                    /usr/local/pf/db
                        /usr/local/pf/db/*
%dir                    /usr/local/pf/docs
%doc                    /usr/local/pf/docs/*.odt
%doc                    /usr/local/pf/docs/fdl-1.2.txt
%dir                    /usr/local/pf/docs/MIB
%doc                    /usr/local/pf/docs/MIB/Inverse-PacketFence-Notification.mib
%dir                    /usr/local/pf/html
%dir                    /usr/local/pf/html/admin
                        /usr/local/pf/html/admin/*
%dir                    /usr/local/pf/html/common
                        /usr/local/pf/html/common/*
%dir                    /usr/local/pf/html/user
%dir                    /usr/local/pf/html/user/3rdparty
                        /usr/local/pf/html/user/3rdparty/timerbar.js
%dir                    /usr/local/pf/html/user/content
%config(noreplace)      /usr/local/pf/html/user/content/footer.html
%config(noreplace)      /usr/local/pf/html/user/content/header.html
%dir                    /usr/local/pf/html/user/content/images
                        /usr/local/pf/html/user/content/images/*
                        /usr/local/pf/html/user/content/index.php
                        /usr/local/pf/html/user/content/style.php
%dir                    /usr/local/pf/html/user/content/templates
%config(noreplace)      /usr/local/pf/html/user/content/templates/*
%dir                    /usr/local/pf/html/user/content/violations
%config(noreplace)      /usr/local/pf/html/user/content/violations/*
%attr(0755, pf, pf)     /usr/local/pf/installer.pl
%dir                    /usr/local/pf/lib
%dir                    /usr/local/pf/lib/pf
                        /usr/local/pf/lib/pf/*.pm
%dir                    /usr/local/pf/lib/pf/floatingdevice
%config(noreplace)      /usr/local/pf/lib/pf/floatingdevice/custom.pm
%dir                    /usr/local/pf/lib/pf/lookup
%config(noreplace)      /usr/local/pf/lib/pf/lookup/node.pm
%config(noreplace)      /usr/local/pf/lib/pf/lookup/person.pm
%dir                    /usr/local/pf/lib/pf/pfcmd
                        /usr/local/pf/lib/pf/pfcmd/*
%dir                    /usr/local/pf/lib/pf/radius
%config(noreplace)      /usr/local/pf/lib/pf/radius/custom.pm
%dir                    /usr/local/pf/lib/pf/SNMP
                        /usr/local/pf/lib/pf/SNMP/*
%dir                    /usr/local/pf/lib/pf/vlan
%config(noreplace)      /usr/local/pf/lib/pf/vlan/custom.pm
%dir                    /usr/local/pf/logs
%doc                    /usr/local/pf/NEWS
%doc                    /usr/local/pf/README
%doc                    /usr/local/pf/README_SWITCHES
%dir                    /usr/local/pf/sbin
%attr(0755, pf, pf)     /usr/local/pf/sbin/pfdetect
%attr(0755, pf, pf)     /usr/local/pf/sbin/pfdhcplistener
%attr(0755, pf, pf)     /usr/local/pf/sbin/pfmon
%attr(0755, pf, pf)     /usr/local/pf/sbin/pfredirect
%attr(0755, pf, pf)     /usr/local/pf/sbin/pfsetvlan
%dir                    /usr/local/pf/test
%attr(0755, pf, pf)     /usr/local/pf/test/connect_and_read.pl
%attr(0755, pf, pf)     /usr/local/pf/test/dhcp_dumper
%doc                    /usr/local/pf/UPGRADE
%dir                    /usr/local/pf/var
%dir                    /usr/local/pf/var/rrd
%dir                    /usr/local/pf/var/session

# Remote snort sensor file list
%files remote-snort-sensor
%defattr(-, pf, pf)
%attr(0755, root, root) %{_initrddir}/pfdetectd
%dir                    /usr/local/pf
%dir                    /usr/local/pf/conf
%config(noreplace)      /usr/local/pf/conf/pfdetect_remote.conf
%dir                    /usr/local/pf/sbin
%attr(0755, pf, pf)     /usr/local/pf/sbin/pfdetect_remote
%dir                    /usr/local/pf/var

%changelog
* Tue May 18 2010 Olivier Bilodeau <obilodeau@inverse.ca>
- Added missing file for Floating Network Device support: 
  floating_network_device.conf

* Fri May 07 2010 Olivier Bilodeau <obilodeau@inverse.ca>
- Added new files for Floating Network Device support
- Added perl(Test::NoWarnings) as a build-time dependency (used for tests)

* Thu May 06 2010 Olivier Bilodeau <obilodeau@inverse.ca>
- Fixed packaging of 802.1x rlm_perl_packetfence_* files and new radius files
- Removing the pinned perl(Parse::RecDescent) version. Fixes #833;
- Snapshot vs releases is now defined by an rpmbuild argument
- source_release should now be passed as an argument to simplify our nightly 
  build system. Fixes #946;
- Fixed a problem with addons/integration-testing files
- Perl required version is now 5.8.8 since a lot of our source files explictly
  ask for 5.8.8. Fixes #868;
- Added perl(Test::MockModule) as a build dependency (required for tests)
- Test modules are now required for building instead of required for package
  install. Fixes #866;

* Thu Apr 29 2010 Olivier Bilodeau <obilodeau@inverse.ca>
- Added mod_perl as a dependency

* Wed Apr 28 2010 Olivier Bilodeau <obilodeau@inverse.ca>
- Added perl(Try::Tiny) and perl(Test::Exception) as a dependency used for 
  exception-handling and its testing
- Linking to new database schema

* Fri Apr 23 2010 Olivier Bilodeau <obilodeau@inverse.ca>
- New addons/integration-testing folder with integration-testing scripts. More
  to come!
- Added perl(Readonly::XS) as a dependency. Readonly becomes faster with it. 

* Mon Apr 19 2010 Olivier Bilodeau <obilodeau@inverse.ca>
- packetfence-remote-snort-sensor back to life. Fixes #888;
  http://www.packetfence.org/mantis/view.php?id=888

* Tue Apr 06 2010 Olivier Bilodeau <obilodeau@inverse.ca> - 1.8.8-0.20100406
- Version bump to snapshot 20100406

* Tue Mar 16 2010 Olivier Bilodeau <obilodeau@inverse.ca> - 1.8.7-2
- Fix upgrade bug from 1.8.4: Changed perl-Locale-gettext dependency to use the
  perl namespace version perl(Locale-gettext). Fixes #931;
  http://www.packetfence.org/mantis/view.php?id=931

* Tue Mar 11 2010 Olivier Bilodeau <obilodeau@inverse.ca> - 1.8.8-0.20100311
- Version bump to snapshot 20100311

* Tue Jan 05 2010 Olivier Bilodeau <obilodeau@inverse.ca> - 1.8.7-1
- Version bump to 1.8.7

* Thu Dec 17 2009 Olivier Bilodeau <obilodeau@inverse.ca> - 1.8.6-3
- Added perl-SOAP-Lite as a dependency of remote-snort-sensor. Fixes #881;
  http://www.packetfence.org/mantis/view.php?id=881
- Added perl-LWP-UserAgent-Determined as a dependency of remote-snort-sensor.
  Fixes #882;
  http://www.packetfence.org/mantis/view.php?id=882

* Tue Dec 04 2009 Olivier Bilodeau <obilodeau@inverse.ca> - 1.8.6-2
- Fixed link to database schema
- Rebuilt packages

* Tue Dec 01 2009 Olivier Bilodeau <obilodeau@inverse.ca> - 1.8.6-1
- Version bump to 1.8.6
- Changed Source of the snapshot releases to packetfence.org

* Fri Nov 20 2009 Olivier Bilodeau <obilodeau@inverse.ca> - 1.8.6-0.20091120
- Version bump to snapshot 20091120
- Changed some default behavior for overwriting config files (for the better)

* Fri Oct 30 2009 Olivier Bilodeau <obilodeau@inverse.ca> - 1.8.5-2
- Modifications made to the dependencies to avoid installing Parse::RecDescent 
  that doesn't work with PacketFence

* Wed Oct 28 2009 Olivier Bilodeau <obilodeau@inverse.ca> - 1.8.5-1
- Version bump to 1.8.5

* Tue Oct 27 2009 Olivier Bilodeau <obilodeau@inverse.ca> - 1.8.5-0.20091027
- Added build instructions to avoid badly named release tarball
- Version bump to snapshot 20091027

* Mon Oct 26 2009 Olivier Bilodeau <obilodeau@inverse.ca> - 1.8.5-0.20091026
- Parse::RecDescent is a build dependency AND a runtime one. Fixes #806;
  http://packetfence.org/mantis/view.php?id=806
- Pulling php-pear-Log instead of php-pear. Fixes #804
  http://packetfence.org/mantis/view.php?id=804
- New dependency for SNMPv3 support with AES: perl-Crypt-Rijndael. Fixes #775;
  http://packetfence.org/mantis/view.php?id=775

* Fri Oct 23 2009 Olivier Bilodeau <obilodeau@inverse.ca> - 1.8.5-0.20091023
- Major improvements to the SPEC file. Starting changelog

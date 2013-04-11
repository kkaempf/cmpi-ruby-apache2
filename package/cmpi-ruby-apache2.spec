#
# spec file for package cmpi-ruby-apache2 (Version 0.1.0)
#
# Copyright (c) 2013 SUSE LINUX Products GmbH, Nuernberg, Germany.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#

# norootforbuild

Name:           cmpi-ruby-apache2
Url:            http://en.opensuse.org/Software_Management/CIM
License:        LGPL-2.1
Group:          System/Management
AutoReqProv:    on
Version:        0.3.0
Release:        2
Summary:        CMPI CIM provider for Apache2
Source0:        %{name}-%{version}.tar.bz2
Requires:       cmpi-bindings-ruby
Requires:       sblim-sfcb
PreReq:         sblim-sfcb
BuildRequires:  sblim-sfcb
BuildRequires:  apache2
BuildRequires:  ruby
BuildRequires:  rubygem(provider-testing)
BuildRequires:  rubygem(cim) 
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch
%define mofdir /usr/share/mof/%{name}
%define cmpidir /usr/share/cmpi
%define namespace root/suse

%description
A simple service provider modeling the Apache2 http server


%prep
%setup -n %{name}

%build

%install
rake install DESTDIR=%{buildroot}

%pre
if [ $1 -gt 1 ]; then
  if [ -d %{mofdir} ]; then
    for i in %{mofdir}/*.reg
    do
      j=`basename $i`
      sfcbunstage -n %{namespace} -r $j `basename $j .reg`.mof
    done
  fi
fi

%post
for i in %{mofdir}/*.reg
do
  sfcbstage -n %{namespace} -r $i %{mofdir}/`basename $i .reg`.mof
done
sfcbrepos -f 

%preun
if [ "$1" = "0" ] ; then
  if [ -d %{mofdir} ]; then
    for i in %{mofdir}/*.reg
    do
      j=`basename $i`
      sfcbunstage -n %{namespace} -r $j `basename $j .reg`.mof
    done
    sfcbrepos -f 
  fi
fi

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%dir %{cmpidir}
%{cmpidir}
%dir %{mofdir}
%{mofdir}

%changelog

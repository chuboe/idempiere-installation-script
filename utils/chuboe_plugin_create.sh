#!/bin/bash

#Next Steps
    # add component definition for process
    # add git and hg ignore

main ()
{
    source chuboe_plugin_create.properties

    CODE_SRC_BASE=$PROP_CODE_LOCATION/$PROP_COMPANY_DOMAIN.$PROP_ENTITY_LOWER.$PROP_CODE_TYPE/
    CODE_SRC_LONG=$CODE_SRC_BASE/src/$PROP_COMPANY_DOMAIN_SUFFIX/$PROP_COMPANY_NAME_LOWER/$PROP_ENTITY_LOWER/$PROP_CODE_TYPE

    echo "HERE: variables"
    echo PROP_VENDOR_NAME = $PROP_VENDOR_NAME
    echo PROP_VENDOR_USER = $PROP_VENDOR_USER
    echo PROP_COMPANY_NAME = $PROP_COMPANY_NAME
    echo PROP_COMPANY_DOMAIN_SUFFIX = $PROP_COMPANY_DOMAIN_SUFFIX
    echo PROP_ENTITY = $PROP_ENTITY
    echo PROP_CODE_TYPE = $PROP_CODE_TYPE

    # derived values
    echo PROP_YEAR = $PROP_YEAR
    echo PROP_COMPANY_DOMAIN = $PROP_COMPANY_DOMAIN
    echo PROP_COMPANY_NAME_CAMEL = $PROP_COMPANY_NAME_CAMEL
    echo PROP_COMPANY_NAME_LOWER = $PROP_COMPANY_NAME_LOWER
    echo PROP_ENTITY_CAMEL = $PROP_ENTITY_CAMEL
    echo PROP_ENTITY_LOWER = $PROP_ENTITY_LOWER
    echo PROP_CODE_LOCATION = $PROP_CODE_LOCATION

    echo $CODE_SRC_BASE
    echo $CODE_SRC_LONG

    echo "HERE: validation"
    RESULT=$([ -d $CODE_SRC_BASE ] && echo "Y" || echo "N")
    if [ $RESULT == "N" ]; then
        echo "HERE: directory does not exist - proceeding"
    else
        echo "HERE: plugin already exists - exiting now!"
        exit 1
    fi

    # make project directories
    echo "HERE: create directories"
    mkdir -p $CODE_SRC_LONG
    mkdir -p $CODE_SRC_BASE/META-INF/
    mkdir -p $CODE_SRC_BASE/OSGI-INF/
    mkdir -p $CODE_SRC_BASE/download/

    # create ignore files
    echo "HERE: create ignore files"
    echo hgignore.f
    hgignore.f | tee $CODE_SRC_BASE/.hgignore
    echo gitignore.f
    gitignore.f | tee $CODE_SRC_BASE/.gitignore

    echo build.properties
    build.properties.f | tee $CODE_SRC_BASE/build.properties
    echo
    echo .classpath
    classpath.f | tee $CODE_SRC_BASE/.classpath
    echo
    echo MANIFEST.MF
    MANIFEST.f | tee $CODE_SRC_BASE/META-INF/MANIFEST.MF
    echo
    echo .project
    project.f | tee $CODE_SRC_BASE/.project
    echo
    echo "$PROP_ENTITY_CAMEL"Factory
    process.factory.f | tee "$CODE_SRC_LONG/$PROP_ENTITY_CAMEL"Factory.java
    echo
    echo $PROP_ENTITY_CAMEL
    process.f | tee $CODE_SRC_LONG/$PROP_ENTITY_CAMEL.java
}

hgignore.f ()
{
cat << EOF
syntax: glob
bin
EOF
}

gitignore.f ()
{
cat << EOF
syntax: glob
bin
EOF
}

build.properties.f ()
{
cat << EOF
bin.includes = META-INF/,\
               .,\
               OSGI-INF/
EOF
}

classpath.f ()
{
cat << EOF
<?xml version="1.0" encoding="UTF-8"?>
<classpath>
	<classpathentry kind="con" path="org.eclipse.jdt.launching.JRE_CONTAINER"/>
	<classpathentry kind="con" path="org.eclipse.pde.core.requiredPlugins"/>
	<classpathentry kind="src" path="src"/>
	<classpathentry kind="output" path="bin"/>
</classpath>
EOF
}

MANIFEST.f ()
{
cat << EOF
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-Name: Process
Bundle-SymbolicName: $PROP_COMPANY_DOMAIN.$PROP_ENTITY_LOWER.$PROP_CODE_TYPE;singleton:=true
Bundle-Version: 1.0.0.qualifier
Bundle-Vendor: $PROP_COMPANY_NAME_LOWER
Automatic-Module-Name: $PROP_COMPANY_DOMAIN.$PROP_ENTITY_LOWER.$PROP_CODE_TYPE
Bundle-RequiredExecutionEnvironment: JavaSE-11
Require-Bundle: org.adempiere.base;bundle-version="6.2.0",
 org.adempiere.plugin.utils;bundle-version="6.2.0",
 org.adempiere.base.process;bundle-version="6.2.0"
Import-Package: org.osgi.framework;version="1.9.0"
Bundle-Activator: org.adempiere.plugin.utils.Incremental2PackActivator
EOF
}

project.f ()
{
cat << EOF
<?xml version="1.0" encoding="UTF-8"?>
<projectDescription>
	<name>$PROP_COMPANY_DOMAIN.$PROP_ENTITY_LOWER.$PROP_CODE_TYPE</name>
	<comment></comment>
	<projects>
	</projects>
	<buildSpec>
		<buildCommand>
			<name>org.eclipse.jdt.core.javabuilder</name>
			<arguments>
			</arguments>
		</buildCommand>
		<buildCommand>
			<name>org.eclipse.pde.ManifestBuilder</name>
			<arguments>
			</arguments>
		</buildCommand>
		<buildCommand>
			<name>org.eclipse.pde.SchemaBuilder</name>
			<arguments>
			</arguments>
		</buildCommand>
	</buildSpec>
	<natures>
		<nature>org.eclipse.pde.PluginNature</nature>
		<nature>org.eclipse.jdt.core.javanature</nature>
	</natures>
</projectDescription>
EOF
}

process.component.f ()
{
cat << EOF
<?xml version="1.0" encoding="UTF-8"?>
<scr:component xmlns:scr="http://www.osgi.org/xmlns/scr/v1.1.0" name="${PROP_COMPANY_DOMAIN}.${PROP_ENTITY_LOWER}.${PROP_CODE_TYPE}Factory">
   <implementation class="${PROP_COMPANY_DOMAIN}.${PROP_ENTITY_LOWER}.${PROP_CODE_TYPE}Factory"/>
   <property name="service.ranking" type="Integer" value="100"/>
   <service>
      <provide interface="org.adempiere.base.IProcessFactory"/>
   </service>
</scr:component>
EOF
}

process.factory.f ()
{
cat << EOF
/******************************************************************************
 * Copyright (C) $PROP_YEAR $PROP_VENDOR_NAME                                             *
 * Product: iDempiere ERP & CRM Smart Business Solution                       *
 * This program is free software; you can redistribute it and/or modify it    *
 * under the terms version 2 of the GNU General Public License as published   *
 * by the Free Software Foundation. This program is distributed in the hope   *
 * that it will be useful, but WITHOUT ANY WARRANTY; without even the implied *
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.           *
 * See the GNU General Public License for more details.                       *
 * You should have received a copy of the GNU General Public License along    *
 * with this program; if not, write to the Free Software Foundation, Inc.,    *
 * 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA.                     *
 *****************************************************************************/

package $PROP_COMPANY_DOMAIN.$PROP_ENTITY_LOWER.$PROP_CODE_TYPE;

import org.adempiere.base.IProcessFactory;
import org.compiere.process.ProcessCall;

/**
 *
 * @author $PROP_VENDOR_USER
 *
 */
public class ${PROP_ENTITY_CAMEL}Factory implements IProcessFactory {

    @Override
    public ProcessCall newProcessInstance(String className) {
        if(className.equals($PROP_ENTITY_CAMEL.class.getName())) {
            return new $PROP_ENTITY_CAMEL();
        }
        return null;
    }

}
EOF
}

process.f ()
{
cat << EOF
/******************************************************************************
 * Copyright (C) $PROP_YEAR $PROP_VENDOR_NAME                                             *
 * Product: iDempiere ERP & CRM Smart Business Solution                       *
 * This program is free software; you can redistribute it and/or modify it    *
 * under the terms version 2 of the GNU General Public License as published   *
 * by the Free Software Foundation. This program is distributed in the hope   *
 * that it will be useful, but WITHOUT ANY WARRANTY; without even the implied *
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.           *
 * See the GNU General Public License for more details.                       *
 * You should have received a copy of the GNU General Public License along    *
 * with this program; if not, write to the Free Software Foundation, Inc.,    *
 * 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA.                     *
 *****************************************************************************/

package $PROP_COMPANY_DOMAIN.$PROP_ENTITY_LOWER.$PROP_CODE_TYPE;

import org.compiere.process.SvrProcess;
import org.compiere.util.Env;

/**
 *
 * @author $PROP_VENDOR_USER
 *
 */
public class $PROP_ENTITY_CAMEL extends SvrProcess{

	@Override
	protected void prepare() {
	}

	@Override
	protected String doIt() throws Exception {
		return "Something";
	}
}
EOF
}

template.f ()
{
cat << EOF
EOF
}

main

exit


#!/bin/bash

#Next Steps
    # add component definition for process
    # add git and hg ignore

main ()
{
    source chuboe_plugin_create.properties

    CODE_SRC_BASE=$PROP_CODE_LOCATION/$PROP_COMPANY_DOMAIN.$PROP_ENTITY_LOWER.$PROP_CODE_TYPE/
    CODE_SRC_LONG=$CODE_SRC_BASE/src/$PROP_COMPANY_DOMAIN_SUFFIX/$PROP_COMPANY_NAME_LOWER/$PROP_ENTITY_LOWER/$PROP_CODE_TYPE

    echo $CODE_SRC_BASE
    echo $CODE_SRC_LONG

    RESULT=$([ -d $CODE_SRC_BASE ] && echo "Y" || echo "N")
    if [ $RESULT == "N" ]; then
        echo "HERE: directory does not exist - proceeding"
    else
        echo "HERE: plugin already exists - exiting now!"
        exit 1
    fi

    mkdir -p $CODE_SRC_LONG
    mkdir -p $CODE_SRC_BASE/META-INF/

    echo build.properties
    build.properties.f | tee $CODE_SRC_BASE/build.properties
    echo
    echo .classpath
    classpath.f | tee $CODE_SRC_BASE/.classpath
    echo
    echo MANIFEST.MF
    MANIFEST.f | tee $CODE_SRC_BASE/META-INF/MANIFEST.MF
    echo
    echo plugin.xml
    plugin.f | tee $CODE_SRC_BASE/plugin.xml
    echo
    echo .project
    project.f | tee $CODE_SRC_BASE/.project
    echo
    echo "$PROP_ENTITY_CAMEL"Factory
    process.factory.f | tee "$CODE_SRC_LONG/$PROP_ENTITY_CAMEL"Factory.java
    echo $PROP_ENTITY_CAMEL
    process.f | tee $CODE_SRC_LONG/$PROP_ENTITY_CAMEL.java
}

build.properties.f ()
{
cat << EOF
source.. = src/
output.. = bin/
bin.includes = META-INF/,\
.,\
plugin.xml
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


plugin.f ()
{
cat << EOF
<?xml version="1.0" encoding="UTF-8"?>
<?eclipse version="3.4"?>
<plugin>
   <extension
         id="$PROP_COMPANY_DOMAIN.$PROP_ENTITY_LOWER.$PROP_CODE_TYPE.$PROP_ENTITY_CAMEL"
         name="$PROP_COMPANY_DOMAIN.$PROP_ENTITY_LOWER.$PROP_CODE_TYPE.$PROP_ENTITY_CAMEL"
         point="org.adempiere.base.Process">
      <process
            class="$PROP_COMPANY_DOMAIN.$PROP_ENTITY_LOWER.$PROP_CODE_TYPE.$PROP_ENTITY_CAMEL">
      </process>
   </extension>
</plugin>
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
public class "$PROP_ENTITY_CAMEL"Factory implements IProcessFactory {
 
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

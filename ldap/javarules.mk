#
# BEGIN COPYRIGHT BLOCK
# This Program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation; version 2 of the License.
# 
# This Program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along with
# this Program; if not, write to the Free Software Foundation, Inc., 59 Temple
# Place, Suite 330, Boston, MA 02111-1307 USA.
# 
# In addition, as a special exception, Red Hat, Inc. gives You the additional
# right to link the code of this Program with code not covered under the GNU
# General Public License ("Non-GPL Code") and to distribute linked combinations
# including the two, subject to the limitations in this paragraph. Non-GPL Code
# permitted under this exception must only link to the code of this Program
# through those well defined interfaces identified in the file named EXCEPTION
# found in the source code files (the "Approved Interfaces"). The files of
# Non-GPL Code may instantiate templates or use macros or inline functions from
# the Approved Interfaces without causing the resulting work to be covered by
# the GNU General Public License. Only Red Hat, Inc. may make changes or
# additions to the list of Approved Interfaces. You must obey the GNU General
# Public License in all respects for all of the Program code and other code used
# in conjunction with the Program except the Non-GPL Code covered by this
# exception. If you modify this file, you may extend this exception to your
# version of the file, but you are not obligated to do so. If you do not wish to
# provide this exception without modification, you must delete this exception
# statement from your version and license this file solely under the GPL without
# exception. 
# 
# 
# Copyright (C) 2001 Sun Microsystems, Inc. Used by permission.
# Copyright (C) 2005 Red Hat, Inc.
# All rights reserved.
# END COPYRIGHT BLOCK
#
# javarules.mk
#
# Identify tools, directories, classpath for building the Directory
# console

# Where the source root is
JAVA_SRC_DIR=$(ABS_ROOT)/ldap/admin/src/java

# Where the class files go
JAVA_BUILD_DIR=$(ABS_ROOT)/built/java/$(BUILD_DEBUG)/admin
JAVA_DEST_DIR=$(BUILD_ROOT)/built/java/$(BUILD_DEBUG)
CLASS_DIR=$(JAVA_DEST_DIR)/admin
DSADMIN_DIR=$(CLASS_DIR)/com/netscape/admin

# Where docs go
DSADMIN_DOC_DIR=$(JAVA_DEST_DIR)/doc


# Java setup ##############################################

# disable optimized builds for now until we can figure out why
# optimized doesn't build . . .
ifeq ($(BUILD_DEBUG),optimize)
#  JAVAFLAGS=-O
  JAVAFLAGS=
else
  JAVAFLAGS=-g
endif

PATH_SEP := :
ifeq ($(OS), Windows_NT)
  GET_JAVA_FROM_PATH := 1
  PATH_SEP := ;
  EXE_SUFFIX := .exe
endif

ifeq ($(INTERNAL_BUILD), 1)
  # For UNIX, use JDK and JAR files over NFS
  ifeq ($(ARCH), Linux)
    JDK_VERSION:=1.4.2_SR3
    JDK_VERSDIR:=ibmjdk/$(JDK_VERSION)/$(NSOBJDIR_NAME)
  else
    ifeq ($(ARCH), HPUX)
      JDK_VERSION:=1.4.2_09
      JDK_VERSDIR:=hpjdk/$(JDK_VERSION)
    else # Solaris
      JDK_VERSION:=1.4.2_10
      JDK_VERSDIR:=jdk/$(JDK_VERSION)/$(NSOBJDIR_NAME)
    endif
  endif	
  JDKLIB:=$(COMPONENTS_DIR)/$(JDK_VERSDIR)/lib/tools.jar
  JAVABINDIR:=$(COMPONENTS_DIR)/$(JDK_VERSDIR)/bin
else # INTERNAL_BUILD
  # Figure out where the java lib .jar files are, from where javac is
  JDKCOMP := $(shell which javac)
  JDKPRELIB := $(subst bin/javac$(EXE_SUFFIX),lib,$(JDKCOMP))
  JDKLIB := $(addprefix $(JDKPRELIB)/,tools.jar)
endif 
	
CLASSPATH := $(JAVA_SRC_DIR)$(PATH_SEP)$(LDAPJARFILE)

ifndef JAVA
  ifdef JAVABINDIR
    JAVA= $(JAVABINDIR)/java
  else
    JAVA=java
  endif
endif

# Some java compilers run out of memory, so must be run as follows
JAVAC_PROG=-mx32m sun.tools.javac.Main
HEAVY_JAVAC=$(JAVA) $(JAVAC_PROG) $(JAVAFLAGS)

ifndef JAVAC
  ifdef JAVABINDIR
    JAVAC= $(JAVABINDIR)/javac $(JAVAFLAGS)
  else
    JAVAC= javac $(JAVAFLAGS)
  endif
endif
ifndef JAVADOC
  JAVADOC=$(JAVA) -mx64m sun.tools.javadoc.Main -classpath "$(CLASSPATH)"
endif

# How to run ant (the Java "make" system)
ifdef GET_ANT_FROM_PATH
ANT = ant
else
ANT = $(JAVA) -Dant.home=$(ANT_HOME) -classpath "$(ANT_CP)$(PATH_SEP)$(JDKLIB)" org.apache.tools.ant.Main
endif

##########################################################

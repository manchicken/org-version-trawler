#!/usr/bin/env perl

### QUICK NOTE FOR THOSE NEW TO PERL
# This is a test file, and it looks different from a normal
# Perl program. I'm using scoping blocks (curlies outside of a function)
# to use lexical scoping for cleaner tests. It's very similar to
# how you'd use `describe()` in JavaScript with Mocha or Jest.
### END NOTE

use Modern::Perl '2020';
use utf8;

# When adding tests, update this. This lets the test harness verify success.
use Test::More;
use Data::Dumper;

BEGIN {
  use_ok 'PackageManager::PomXml';
}

# Slurp the __DATA__
my $xmlData = undef;
{
  local $/ = undef;
  $xmlData = <DATA>;
}

# Let's make sure the regex works
{
  my $pm_deets = PackageManager::PomXml->package_manager_details;

  is $pm_deets->{name}, 'Maven POM', 'Verify name.';
  my $re = $pm_deets->{re};

  # Let's make sure these patterns match
  for my $name (
    qw?
    pom.xml
    Pom.xml
    test-pom.xml
    pom-test.xml
    lib/foo/pom.xml
    lib/foo/test-pom.xml
    lib/foo/pom-test.xml
    1/pom2.xml
    ?)
  {
    like $name, $re, "Matches: $name";
  }

  # Let's verify these _don't_ match
  for my $name (qw?
    foo.xml
    pompelmous.xml
  ?) {
    unlike $name, $re, "Doesn't match: $name";
  }
}

# Let's make sure we can parse out the dependencies..
{
  my $t = PackageManager::PomXml->new($xmlData);
  isa_ok $t, 'PackageManager::PomXml', 'First file, got an instance.';
  ok $t->has_dependencies, 'Verify that we have dependencies.';
  is_deeply $t->next_dependency, {
            'version' => '4.3.9.RELEASE',
            'package' => 'spring-core'
          }, 'Verify spring-core as the first dependency.';
  is_deeply $t->{deps}, [
          {
            'package' => 'spring-web',
            'version' => '4.3.9.RELEASE'
          },
          {
            'version' => '4.3.9.RELEASE',
            'package' => 'spring-context'
          },
          {
            'version' => '4.3.9.RELEASE',
            'package' => 'spring-beans'
          },
          {
            'package' => 'spring-expression',
            'version' => '4.3.9.RELEASE'
          },
          {
            'package' => 'spring-webmvc',
            'version' => '4.3.9.RELEASE'
          },
          {
            'package' => 'spring-tx',
            'version' => '4.3.9.RELEASE'
          },
          {
            'version' => '4.3.9.RELEASE',
            'package' => 'spring-context-support'
          },
          {
            'package' => 'spring-jdbc',
            'version' => '4.3.9.RELEASE'
          },
          {
            'package' => 'spring-test',
            'version' => '4.3.9.RELEASE'
          },
          {
            'version' => '4.3.9.RELEASE',
            'package' => 'spring-aop'
          },
          {
            'package' => 'slf4j-api',
            'version' => '1.7.9'
          },
          {
            'version' => '1.7.9',
            'package' => 'jcl-over-slf4j'
          },
          {
            'version' => '1.2.9',
            'package' => 'fastjson'
          },
          {
            'version' => '3.4.2',
            'package' => 'mybatis'
          },
          {
            'version' => '1.3.1',
            'package' => 'mybatis-spring'
          },
          {
            'version' => '5.1.38',
            'package' => 'mysql-connector-java'
          },
          {
            'version' => '1.0.15',
            'package' => 'druid'
          },
          {
            'version' => '4.1.2',
            'package' => 'pagehelper'
          },
          {
            'package' => 'hibernate-validator',
            'version' => '5.1.0.Final'
          },
          {
            'package' => 'dubbo',
            'version' => '2.5.3'
          },
          {
            'version' => '0.5',
            'package' => 'zkclient'
          },
          {
            'version' => '1.8.9',
            'package' => 'aspectjweaver'
          },
          {
            'version' => '4.12',
            'package' => 'junit'
          },
          {
            'version' => '2.7',
            'package' => 'gson'
          },
          {
            'version' => '2.2.4',
            'package' => 'javax.el-api'
          },
          {
            'version' => '2.2.4',
            'package' => 'javax.el'
          },
          {
            'version' => '2.2',
            'package' => 'cglib-nodep'
          },
          {
            'version' => '2.2.2',
            'package' => 'cglib'
          },
          {
            'package' => 'commons-codec',
            'version' => '1.7'
          },
          {
            'version' => '2.1.0',
            'package' => 'mockito-core'
          },
          {
            'version' => '3.4.8',
            'package' => 'zookeeper'
          },
          {
            'version' => '3.4',
            'package' => 'commons-lang3'
          },
          {
            'package' => 'commons-logging',
            'version' => '1.1.3'
          },
          {
            'version' => '4.3.2',
            'package' => 'httpcore'
          },
          {
            'version' => '4.3.3',
            'package' => 'httpclient'
          },
          {
            'version' => '16.0.1',
            'package' => 'guava'
          },
          {
            'package' => 'javax.servlet-api',
            'version' => '3.0.1'
          }
        ], 'Expected dependencies.';
}

{
  my $pomTwo = <<'EOF';
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <groupId>fooo</groupId>
  <artifactId>Fooo</artifactId>
  <version>0.0.8</version>
  <dependencies>
    <dependency>
      <groupId>org.apache.maven.plugins</groupId>
      <artifactId>maven-assembly-plugin</artifactId>
      <version>2.6</version>
    </dependency>
    <dependency>
      <groupId>org.coursera</groupId>
      <artifactId>metrics-datadog</artifactId>
      <version>1.1.4</version>
    </dependency>
    <dependency>
      <groupId>com.google.code.gson</groupId>
      <artifactId>gson</artifactId>
      <version>2.3.1</version>
    </dependency>
  <dependency>
    <groupId>junit</groupId>
    <artifactId>junit</artifactId>
    <version>4.7</version>
  </dependency>
  <dependency>
    <groupId>org.apache.spark</groupId>
    <artifactId>spark-core_2.10</artifactId>
    <version>2.1.0</version>
    <exclusions>
    <exclusion>
      <groupId>org.slf4j</groupId>
      <artifactId>slf4j-log4j12</artifactId>
    </exclusion>
    </exclusions>
  </dependency>
  <dependency>
    <groupId>org.apache.spark</groupId>
    <artifactId>spark-mllib_2.10</artifactId>
    <version>2.1.0</version>
  </dependency>
  <dependency>
    <groupId>org.mongodb</groupId>
    <artifactId>mongo-java-driver</artifactId>
    <version>3.8.0</version>
  </dependency>
    <dependency>
      <groupId>org.mongodb</groupId>
      <artifactId>mongo-hadoop-core</artifactId>
      <version>1.3.0</version>
    </dependency>
  <!-- Mongo Java mapping -->
  <dependency>
    <groupId>org.mongojack</groupId>
    <artifactId>mongojack</artifactId>
    <version>2.1.0</version>
  </dependency>
    <dependency>
      <groupId>org.apache.httpcomponents</groupId>
      <artifactId>httpclient</artifactId>
      <version>4.5.2</version>
    </dependency>

  <!-- jackson mapper -->
  <dependency>
    <groupId>org.codehaus.jackson</groupId>
    <artifactId>jackson-mapper-asl</artifactId>
    <version>1.9.13</version>
  </dependency>

  <dependency>
    <groupId>com.amazonaws</groupId>
    <artifactId>aws-java-sdk</artifactId>
    <version>1.9.8</version>
  </dependency>

  <!-- logging -->
  <dependency>
    <groupId>org.slf4j</groupId>
    <artifactId>slf4j-api</artifactId>
    <version>1.7.10</version>
  </dependency>

  <dependency>
    <groupId>ch.qos.logback</groupId>
    <artifactId>logback-classic</artifactId>
    <version>1.1.2</version>
  </dependency>
  <dependency>
    <groupId>com.google.code.gson</groupId>
    <artifactId>gson</artifactId>
    <version>2.3.1</version>
  </dependency>

    <dependency>
      <groupId>org.msgpack</groupId>
      <artifactId>msgpack</artifactId>
      <version>0.6.8</version>
    </dependency>

  </dependencies>

  <build>
  <resources>
    <resource>
    <directory>src/main/resources</directory>
    <filtering>true</filtering>
    </resource>
  </resources>
  <plugins>
    <plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-dependency-plugin</artifactId>
    <version>2.5.1</version>
    <executions>
      <execution>
      <id>copy-dependencies</id>
      <phase>package</phase>
      <goals>
        <goal>copy-dependencies</goal>
      </goals>
      <configuration>
        <outputDirectory>${project.build.directory}/lib/</outputDirectory>
        <!-- <includeArtifactIds>logback-core,jackson-mapper-asl,aws-java-sdk,mongojack,amqp-client,mongo-java-driver,slf4j-api,logback-classic,mongoHadoop</includeArtifactIds> -->
        <excludeArtifactIds>spark-mllib_2.10,hadoop-client,hadoop-core</excludeArtifactIds>
        <excludeTransitive>false</excludeTransitive>
      </configuration>
      </execution>
    </executions>
    </plugin>
    <plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-compiler-plugin</artifactId>
    <configuration>
      <source>1.7</source>
      <target>1.7</target>
    </configuration>
    </plugin>
    <plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-jar-plugin</artifactId>
    <version>2.5</version>
    <configuration>
      <excludes>
      <exclude>*.properties</exclude>
      <exclude>*.xml</exclude>
      </excludes>
    </configuration>
    </plugin>
    <plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-assembly-plugin</artifactId>
        <version>2.6</version>
    <configuration>
      <descriptor>src/main/resources/bin.xml</descriptor>
          <appendAssemblyId>false</appendAssemblyId>
      <finalName>${project.artifactId}-${project.version}</finalName>
    </configuration>
    </plugin>
  </plugins>
  <filters>
    <filter>../Profiles/${build.profile.id}.properties</filter>
  </filters>
  </build>
  
  <profiles>
  <profile>
    <id>dev</id>
    <activation>
    <activeByDefault>true</activeByDefault>
    </activation>
    <properties>
    <build.profile.id>dev</build.profile.id>
    </properties>
  </profile>
  <profile>
    <id>prod</id>
    <properties>
    <build.profile.id>prod</build.profile.id>
    </properties>
  </profile>
  </profiles>
</project>
EOF
  ;

  my $t = PackageManager::PomXml->new($pomTwo);
  isa_ok $t, 'PackageManager::PomXml', 'For second one, got an instance.';
  ok $t->has_dependencies, 'Second file has dependencies.';
  is_deeply $t->next_dependency, {
            'version' => '2.6',
            'package' => 'maven-assembly-plugin',
          }, 'Verify maven-assembly-plugin as the first dependency for the second file.'; 
}

done_testing();

# The __DATA__ block, in Perl, allows you to embed a built-in file
# with your code. You can then read the __DATA__ block using <DATA>

__DATA__
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <groupId>com.zsy</groupId>
  <artifactId>iYoung-dubbo-v2</artifactId>
  <packaging>pom</packaging>
  <version>1.0-SNAPSHOT</version>
  <modules>
    <module>iYoung-service</module>
    <module>iYoung-web</module>
    <module>iYoung-biz</module>
    <module>iYoung-common</module>
    <module>iYoung-integrate</module>
    <module>iYoung-dao</module>
  </modules>
  <properties>
    <alibaba.dubbo.version>2.5.3</alibaba.dubbo.version>
    <alibaba.druid.version>1.0.15</alibaba.druid.version>
    <alibaba.fastjson.version>1.2.9</alibaba.fastjson.version>
    <apache.poi.version>3.9</apache.poi.version>
    <apache.thrift.version>0.9.1</apache.thrift.version>
    <apache.zookeeper.version>3.4.8</apache.zookeeper.version>
    <aspectj.version>1.8.9</aspectj.version>
    <cglib-nodep.version>2.2</cglib-nodep.version>
    <cglib.version>2.2.2</cglib.version>
    <common-lang.version>2.4</common-lang.version>
    <commons-lang3.version>3.4</commons-lang3.version>
    <commons-logging.version>1.1.3</commons-logging.version>
    <commons-codec.version>1.7</commons-codec.version>
    <common-collections.version>3.2.1</common-collections.version>
    <commons-httpclient.version>3.1</commons-httpclient.version>
    <compiler-plugin.source.version>1.7</compiler-plugin.source.version>
    <compiler-plugin.target.version>1.7</compiler-plugin.target.version>
    <curator-framework.version>1.1.10</curator-framework.version>
    <dom4j.version>1.6.1</dom4j.version>
    <el.version>2.2.4</el.version>
    <github.pagehelper.version>4.1.2</github.pagehelper.version>
    <gson.version>2.7</gson.version>
    <guava.version>16.0.1</guava.version>
    <hibernate-validator.version>5.1.0.Final</hibernate-validator.version>
    <httpcore.version>4.3.2</httpcore.version>
    <httpclient.version>4.3.3</httpclient.version>
    <jar.source>1.7</jar.source>
    <jar.target>1.7</jar.target>
    <javax-mail.version>1.5.2</javax-mail.version>
    <javax.servlet-api.version>3.1.0</javax.servlet-api.version>
    <javax.ws.rs-api.version>2.0</javax.ws.rs-api.version>
    <jolbox.bonecp.version>0.8.0.RELEASE</jolbox.bonecp.version>
    <junit.version>4.12</junit.version>
    <log4j.version>1.2.17</log4j.version>
    <log-util.version>1.0.1</log-util.version>
    <maven-compiler-plugin.version>3.3</maven-compiler-plugin.version>
    <maven-install-plugin.version>2.5.2</maven-install-plugin.version>
    <maven-resources-plugin.version>2.6</maven-resources-plugin.version>
    <maven-jar-plugin.version>2.6</maven-jar-plugin.version>
    <!--todo 这里跑单测的时候需要关闭，但是上线前要记得打开-->
    <maven.test.skip>true</maven.test.skip>
    <maven-war-plugin.version>2.6</maven-war-plugin.version>
    <mockito-core.version>2.1.0</mockito-core.version>
    <mybatis.version>3.4.2</mybatis.version>
    <mybatis-spring.version>1.3.1</mybatis-spring.version>
    <mysql-connector.version>5.1.38</mysql-connector.version>
    <mybatis-ehcache.version>1.0.3</mybatis-ehcache.version>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    <profiles.dir>src/main/profiles</profiles.dir>
    <redis-client.version>2.8.2</redis-client.version>
    <servlet.version>3.0.1</servlet.version>
    <slf4j.version>1.7.9</slf4j.version>
    <spring.version>4.3.9.RELEASE</spring.version>
    <spring-data-redis.version>1.7.5.RELEASE</spring-data-redis.version>
    <toolkit-common-dubbo.version>1.1.5</toolkit-common-dubbo.version>
    <velocity.version>1.7</velocity.version>
    <velocity-tool.version>2.0</velocity-tool.version>
    <validation-api.version>1.1.0.Final</validation-api.version>
    <zaxxer.HikariCP-java6.version>2.3.12</zaxxer.HikariCP-java6.version>
    <zkclient.version>0.5</zkclient.version>
  </properties>
  <dependencyManagement>
    <dependencies>
      <!-- Spring dependencies -->
      <dependency>
        <groupId>org.springframework</groupId>
        <artifactId>spring-core</artifactId>
        <version>${spring.version}</version>
      </dependency>
      <dependency>
        <groupId>org.springframework</groupId>
        <artifactId>spring-web</artifactId>
        <version>${spring.version}</version>
      </dependency>
      <dependency>
        <groupId>org.springframework</groupId>
        <artifactId>spring-context</artifactId>
        <version>${spring.version}</version>
      </dependency>
      <dependency>
        <groupId>org.springframework</groupId>
        <artifactId>spring-beans</artifactId>
        <version>${spring.version}</version>
      </dependency>
      <dependency>
        <groupId>org.springframework</groupId>
        <artifactId>spring-expression</artifactId>
        <version>${spring.version}</version>
      </dependency>
      <dependency>
        <groupId>org.springframework</groupId>
        <artifactId>spring-webmvc</artifactId>
        <version>${spring.version}</version>
      </dependency>
      <dependency>
        <groupId>org.springframework</groupId>
        <artifactId>spring-tx</artifactId>
        <version>${spring.version}</version>
      </dependency>
      <dependency>
        <groupId>org.springframework</groupId>
        <artifactId>spring-context-support</artifactId>
        <version>${spring.version}</version>
      </dependency>
      <dependency>
        <groupId>org.springframework</groupId>
        <artifactId>spring-jdbc</artifactId>
        <version>${spring.version}</version>
      </dependency>
      <dependency>
        <groupId>org.springframework</groupId>
        <artifactId>spring-test</artifactId>
        <version>${spring.version}</version>
        <scope>test</scope>
      </dependency>
      <dependency>
        <groupId>org.springframework</groupId>
        <artifactId>spring-aop</artifactId>
        <version>${spring.version}</version>
      </dependency>

      <!-- logger -->
      <dependency>
        <groupId>org.slf4j</groupId>
        <artifactId>slf4j-api</artifactId>
        <version>${slf4j.version}</version>
      </dependency>
      <dependency>
        <groupId>org.slf4j</groupId>
        <artifactId>jcl-over-slf4j</artifactId>
        <version>${slf4j.version}</version>
      </dependency>
      <dependency>
        <groupId>com.alibaba</groupId>
        <artifactId>fastjson</artifactId>
        <version>${alibaba.fastjson.version}</version>
      </dependency>

      <!-- mybatis-->
      <dependency>
        <groupId>org.mybatis</groupId>
        <artifactId>mybatis</artifactId>
        <version>${mybatis.version}</version>
      </dependency>
      <dependency>
        <groupId>org.mybatis</groupId>
        <artifactId>mybatis-spring</artifactId>
        <version>${mybatis-spring.version}</version>
      </dependency>
      <dependency>
        <groupId>mysql</groupId>
        <artifactId>mysql-connector-java</artifactId>
        <version>${mysql-connector.version}</version>
      </dependency>

      <!--druid数据源-->
      <dependency>
        <groupId>com.alibaba</groupId>
        <artifactId>druid</artifactId>
        <version>${alibaba.druid.version}</version>
      </dependency>
      <dependency>
        <groupId>com.github.pagehelper</groupId>
        <artifactId>pagehelper</artifactId>
        <version>${github.pagehelper.version}</version>
      </dependency>

      <!-- JSR303 Bean Validation-->
      <dependency>
        <groupId>org.hibernate</groupId>
        <artifactId>hibernate-validator</artifactId>
        <version>${hibernate-validator.version}</version>
      </dependency>

      <!-- dubbo -->
      <dependency>
        <groupId>com.alibaba</groupId>
        <artifactId>dubbo</artifactId>
        <version>${alibaba.dubbo.version}</version>
        <exclusions>
          <exclusion>
            <groupId>log4j</groupId>
            <artifactId>log4j</artifactId>
          </exclusion>
        </exclusions>
      </dependency>
      <dependency>
        <groupId>com.101tec</groupId>
        <artifactId>zkclient</artifactId>
        <version>${zkclient.version}</version>
        <exclusions>
          <exclusion>
            <groupId>org.slf4j</groupId>
            <artifactId>slf4j-log4j12</artifactId>
          </exclusion>
          <exclusion>
            <groupId>log4j</groupId>
            <artifactId>log4j</artifactId>
          </exclusion>
        </exclusions>
      </dependency>

      <dependency>
        <groupId>org.aspectj</groupId>
        <artifactId>aspectjweaver</artifactId>
        <version>${aspectj.version}</version>
      </dependency>

      <dependency>
        <groupId>junit</groupId>
        <artifactId>junit</artifactId>
        <version>${junit.version}</version>
        <scope>test</scope>
      </dependency>

      <dependency>
        <groupId>com.google.code.gson</groupId>
        <artifactId>gson</artifactId>
        <version>${gson.version}</version>
      </dependency>
      <!--Bean Validate-->
      <dependency>
        <groupId>javax.el</groupId>
        <artifactId>javax.el-api</artifactId>
        <version>${el.version}</version>
      </dependency>

      <dependency>
        <groupId>org.glassfish.web</groupId>
        <artifactId>javax.el</artifactId>
        <version>${el.version}</version>
      </dependency>

      <dependency>
        <groupId>cglib</groupId>
        <artifactId>cglib-nodep</artifactId>
        <version>${cglib-nodep.version}</version>
      </dependency>
      <dependency>
        <groupId>cglib</groupId>
        <artifactId>cglib</artifactId>
        <version>${cglib.version}</version>
      </dependency>
      <!--mybatis generator-->


      <dependency>
        <groupId>commons-codec</groupId>
        <artifactId>commons-codec</artifactId>
        <version>${commons-codec.version}</version>
      </dependency>

      <dependency>
        <groupId>org.mockito</groupId>
        <artifactId>mockito-core</artifactId>
        <version>${mockito-core.version}</version>
      </dependency>

      <dependency>
        <groupId>org.apache.zookeeper</groupId>
        <artifactId>zookeeper</artifactId>
        <version>${apache.zookeeper.version}</version>
      </dependency>
      <dependency>
        <groupId>org.apache.commons</groupId>
        <artifactId>commons-lang3</artifactId>
        <version>${commons-lang3.version}</version>
      </dependency>
      <dependency>
        <groupId>commons-logging</groupId>
        <artifactId>commons-logging</artifactId>
        <version>${commons-logging.version}</version>
      </dependency>
      <dependency>
        <groupId>org.apache.httpcomponents</groupId>
        <artifactId>httpcore</artifactId>
        <version>${httpcore.version}</version>
      </dependency>
      <dependency>
        <groupId>org.apache.httpcomponents</groupId>
        <artifactId>httpclient</artifactId>
        <version>${httpclient.version}</version>
      </dependency>

      <dependency>
        <groupId>com.google.guava</groupId>
        <artifactId>guava</artifactId>
        <version>${guava.version}</version>
      </dependency>

      <dependency>
        <groupId>javax.servlet</groupId>
        <artifactId>javax.servlet-api</artifactId>
        <version>${servlet.version}</version>
        <scope>provided</scope>
      </dependency>
    </dependencies>
  </dependencyManagement>

  <build>
    <!-- 配置插件 -->
    <finalName>iYoung-dubbo</finalName>
    <pluginManagement>
      <plugins>
        <!-- 编译插件 -->
        <plugin>
          <groupId>org.apache.maven.plugins</groupId>
          <artifactId>maven-compiler-plugin</artifactId>
          <version>${maven-compiler-plugin.version}</version>
          <configuration>
            <source>${compiler-plugin.source.version}</source>
            <target>${compiler-plugin.target.version}</target>
            <encoding>UTF-8</encoding>
          </configuration>
        </plugin>
        <plugin>
          <!-- 打包插件 -->
          <groupId>org.apache.maven.plugins</groupId>
          <artifactId>maven-jar-plugin</artifactId>
          <version>${maven-jar-plugin.version}</version>
        </plugin>
        <plugin>
          <groupId>org.apache.maven.plugins</groupId>
          <artifactId>maven-enforcer-plugin</artifactId>
          <version>1.4.1</version>
          <executions>
            <execution>
              <id>default-cli</id>
              <goals>
                <goal>enforce</goal>
              </goals>
              <configuration>
                <rules>
                  <requireReleaseDeps>
                    <message>ERROR: No Snapshots Allowed!</message>
                  </requireReleaseDeps>
                </rules>
                <fail>true</fail>
              </configuration>
            </execution>
          </executions>
        </plugin>
        <plugin>
          <!-- 安装插件 -->
          <groupId>org.apache.maven.plugins</groupId>
          <artifactId>maven-install-plugin</artifactId>
          <version>${maven-install-plugin.version}</version>
        </plugin>
        <plugin>
          <groupId>org.apache.maven.plugins</groupId>
          <artifactId>maven-resources-plugin</artifactId>
          <version>${maven-resources-plugin.version}</version>
          <configuration>
            <encoding>UTF-8</encoding>
          </configuration>
        </plugin>
        <plugin>
          <groupId>org.apache.maven.plugins</groupId>
          <artifactId>maven-dependency-plugin</artifactId>
          <version>2.8</version>
        </plugin>
        <plugin>
          <groupId>org.apache.maven.plugins</groupId>
          <artifactId>maven-surefire-plugin</artifactId>
          <version>2.12.4</version>
        </plugin>

        <plugin>
          <groupId>org.apache.maven.plugins</groupId>
          <artifactId>maven-archetype-plugin</artifactId>
          <version>2.4</version>
        </plugin>
        <plugin>
          <groupId>org.apache.maven.plugins</groupId>
          <artifactId>maven-war-plugin</artifactId>
          <version>${maven-war-plugin.version}</version>
        </plugin>

      </plugins>
    </pluginManagement>
  </build>

</project>

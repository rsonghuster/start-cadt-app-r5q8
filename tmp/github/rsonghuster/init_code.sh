runtime=$1
codeUri=$2
# for example: index.js、 index.py
handler=$3

if [ -d $codeUri ]; then
  echo "dir $codeUri is inited!";
  exit 0
fi

echo "create dir $codeUri";
mkdir -p $codeUri

if [ "$runtime" = "nodejs12" ] || [ "$runtime" = "nodejs14" ] || [ "$runtime" = "nodejs16" ]; then
cat <<'EOF' > $codeUri/$handler
'use strict';
/*
To enable the initializer feature (https://help.aliyun.com/document_detail/156876.html)
please implement the initializer function as below：
exports.initializer = (context, callback) => {
  console.log('initializing');
  callback(null, '');
};
*/
exports.handler = (event, context, callback) => {
  // const eventObj = JSON.parse(event.toString());
  console.log('hello world');
  callback(null, 'hello world');
}
EOF
fi


if [ "$runtime" = "python3" ] || [ "$runtime" = "python3.9" ] || [ "$runtime" = "python3.10" ]; then
cat <<'EOF' > $codeUri/$handler
# -*- coding: utf-8 -*-
import logging
import json

# To enable the initializer feature (https://help.aliyun.com/document_detail/158208.html)
# please implement the initializer function as below：
# def initializer(context):
#   logger = logging.getLogger()
#   logger.info('initializing')

def handler(event, context):
  # evt = json.loads(event)
  logger = logging.getLogger()
  logger.info('hello world')
  return 'hello world'
EOF
fi


if [ "$runtime" = "php7.2" ]; then
cat <<'EOF' > $codeUri/$handler
<?php

/*
To enable the initializer feature (https://help.aliyun.com/document_detail/89029.html)
please implement the initializer function as below：
function initializer($context) {
  $logger = $GLOBALS['fcLogger'];
  $logger->info('initializing');
}
*/

function handler($event, $context) {
  $logger = $GLOBALS['fcLogger'];
  $logger->info('hello world');
  return 'hello world';
}
EOF
fi


if [ "$runtime" = "go1" ]; then
cat <<'EOF' > $codeUri/$handler.go
package main

import (
	"fmt"

	"github.com/aliyun/fc-runtime-go-sdk/fc"
)

func main() {
	fc.Start(HandleRequest)
}

func HandleRequest(event []byte) (string, error) {
	fmt.Printf("event: %s\n", string(event))
	fmt.Println("hello world! 你好，世界!")
	return "hello world! 你好，世界!", nil
}
EOF
cat <<'EOF' > $codeUri/$handler.mod
module main

require github.com/aliyun/fc-runtime-go-sdk v0.2.7
EOF
fi


if [ "$runtime" = "dotnetcore3.1" ]; then
cat <<'EOF' > $codeUri/$handler.csproj
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>netcoreapp3.1</TargetFramework>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Aliyun.Serverless.Core" Version="1.0.1" />
  </ItemGroup>

</Project>
EOF
cat <<'EOF' > $codeUri/Program.cs
using System;
using System.IO;
using System.Text;
using System.Threading.Tasks;
using Aliyun.Serverless.Core;
using Microsoft.Extensions.Logging;

namespace Example
{
    public class Hello
    {
        public async Task<Stream> StreamHandler(Stream input, IFcContext context)
        {
            string strtxt="hello world! 你好，世界！";
            byte[] bytetxt = Encoding.UTF8.GetBytes(strtxt);
            Console.WriteLine(strtxt);
            MemoryStream ms = new MemoryStream();
            await input.CopyToAsync(ms);
            ms.Write(bytetxt, 0, bytetxt.Length);
            return ms;
        }

        static void Main(string[] args){}
    }
}
EOF
fi


if [ "$runtime" = "java8" ]|| [ "$runtime" = "java11" ]; then
cat <<'EOF' > $codeUri/pom.xml
<project xmlns="http://maven.apache.org/POM/4.0.0"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <groupId>example</groupId>
  <artifactId>HelloFCJava</artifactId>
  <packaging>jar</packaging>
  <version>1.0-SNAPSHOT</version>
  <name>HelloFCJava</name>

  <dependencies>
    <dependency>
      <groupId>junit</groupId>
      <artifactId>junit</artifactId>
      <version>3.8.1</version>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>com.aliyun.fc.runtime</groupId>
      <artifactId>fc-java-core</artifactId>
      <version>1.3.0</version>
    </dependency>
  </dependencies>

  <build>
    <plugins>
      <plugin>
        <artifactId>maven-assembly-plugin</artifactId>
        <configuration>
          <descriptorRefs>
            <descriptorRef>jar-with-dependencies</descriptorRef>
          </descriptorRefs>
        </configuration>
        <executions>
          <execution>
            <id>make-my-jar-with-dependencies</id>
            <phase>package</phase>
            <goals>
              <goal>single</goal>
            </goals>
          </execution>
        </executions>
      </plugin>
    </plugins>
  </build>

  <!-- <properties>
    <maven.compiler.release>11</maven.compiler.release>
    <maven.compiler.target>11</maven.compiler.target>
    <maven.compiler.source>11</maven.compiler.source>
    <maven.test.skip>true</maven.test.skip>
  </properties> -->
</project>
EOF

package=$(echo "$handler" | cut -d '.' -f1)
cls=$(echo "$handler" | cut -d '.' -f2)

mkdir -p $codeUri/src/main/java/$package
cat <<'EOF' > $codeUri/src/main/java/$package/$cls.java
package example;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

import com.aliyun.fc.runtime.Context;
import com.aliyun.fc.runtime.StreamRequestHandler;
import com.aliyun.fc.runtime.FunctionInitializer;

/**
 * Hello world!
 *
 */
public class App implements StreamRequestHandler, FunctionInitializer {

    public void initialize(Context context) throws IOException {
        // TODO
    }

    @Override
    public void handleRequest(
            InputStream inputStream, OutputStream outputStream, Context context) throws IOException {
        outputStream.write(new String("hello world " + this.convert(inputStream)).getBytes());
    }

    public String convert(InputStream inputStream) throws IOException {
        ByteArrayOutputStream result = new ByteArrayOutputStream();
        byte[] buffer = new byte[1024];
        int length;
        while ((length = inputStream.read(buffer)) != -1) {
            result.write(buffer, 0, length);
        }
        return result.toString("UTF-8");
    }
}
EOF
fi

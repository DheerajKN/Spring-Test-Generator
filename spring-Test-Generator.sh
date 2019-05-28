#!/bin/bash 

dir=springTests

if [ -d "$dir" ]; then
  echo -e "\033[1;31mIt seems springTests directory exists in this folder, so we would prefer you to delete it to avoid weird results? y | n"
  read dirDelResponse
  if [ $dirDelResponse = "y" ] ; then rm -rf springTests; else exit 1; fi
fi

mkdir -p ${dir}
if [ -e $1 ]; then
  if [ ! $1 == *.json ]; then
    echo -e "\033[1;31mProvided file type $1 is not json. Please Check"
    exit 1;
  fi
  else
    echo -e "\033[1;31m $1 File doesn't exists. Please Check"
    exit 1;
fi

package=$(echo "${content}" | jq -r '.package' $1)
[ $package = "null" ] && { echo -e "\033[1;31mpackage key is missing from json. 
Include the package data of the main file present in project's test directory Exiting..."; exit 1; }

#init Data
if [[ $* == *--initialData* ]]; then
	echo "package ${package};

public enum ContentType 
{
	JSON,TEXT_PLAIN
}"  > "${dir}/ContentType.java"

echo "package com.calf.care;

public class ApplicationConfig 
{
	public static final String OAUTH_CLIENT_ID = \"admin\";
	public static final String OAUTH_CLIENT_SECRET = \"admin123\";
	public static final String DEFAULT_PASS = \"12345678\";
	public static final String DEFAULT_NAME = \"hbbwd@gmail.com\";
}" >> "${dir}/ApplicationConfig.java"

	baseTest="package ${package};
​
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.httpBasic;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
​
import java.io.IOException;
import java.nio.charset.Charset;
​
import org.junit.Before;
import org.junit.Ignore;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.json.JacksonJsonParser;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.web.FilterChainProxy;
import org.springframework.test.context.junit4.SpringRunner;
import org.springframework.test.context.web.WebAppConfiguration;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.ResultMatcher;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.context.WebApplicationContext;
​
import ${package}.ContentType;
import com.fasterxml.jackson.databind.ObjectMapper;
​
@RunWith(SpringRunner.class)
@WebAppConfiguration
@SpringBootTest(classes = SpringApplication.class)
@Ignore
public abstract class BaseTest {
​
  @Autowired
  private WebApplicationContext wac;
 
  protected MockMvc mockMvc;
  
  public abstract User createAndReturnRandomUserForTesting();
"

	if [[ ! $* == *--no-auth* ]]; then
  baseTest+="
	@Autowired
  private FilterChainProxy springSecurityFilterChain;
	
	@Before
  public void setup() {
    this.mockMvc = MockMvcBuilders.webAppContextSetup(this.wac)
     .addFilter(springSecurityFilterChain).build();
  }

	protected String obtainAccessToken(String username, String password, String clientId, String secret) throws Exception {
	 		
		MultiValueMap<String, String> params = new LinkedMultiValueMap<>();
    params.add(\"grant_type\", \"password\");
    params.add(\"scope\", \"mobileclient\");
    params.add(\"username\", username);
    params.add(\"password\", password);
   
    ResultActions result 
     = mockMvc.perform(post(\"/oauth/token\")
      .params(params)
      .with(httpBasic(clientId,secret))
      .accept(\"application/json;charset=UTF-8\"))
      .andExpect(status().isOk())
      .andExpect(content().contentType(\"application/json;charset=UTF-8\"));
   
    String resultString = result.andReturn().getResponse().getContentAsString();
   
    JacksonJsonParser jsonParser = new JacksonJsonParser();
    return jsonParser.parseMap(resultString).get(\"access_token\").toString();
  }
  
  public void executeGetRequest(String url, String accessToken, ContentType contentType, 
  		ResultMatcher... matchers) throws Exception{
		MockHttpServletRequestBuilder builder = get(url);
		builder.header(\"Authorization\", \"Bearer \" + accessToken);
		executeRequest(builder, contentType, null, matchers);
	}

	  public void executePostRequest(String url, String accessToken, ContentType contentType, 
			byte[] content, ResultMatcher... matchers) throws Exception{
​
		MockHttpServletRequestBuilder builder = post(url);
		builder.header(\"Authorization\", \"Bearer \" + accessToken);
		executeRequest(builder, contentType, content, matchers);  	
	}

	  public void executePutRequest(String url, String accessToken, ContentType contentType, 
			byte[] content, ResultMatcher... matchers) throws Exception{
​
		MockHttpServletRequestBuilder builder = put(url);
		builder.header(\"Authorization\", \"Bearer \" + accessToken);
		executeRequest(builder, contentType, content, matchers);  	
	}

	public void executeDeleteRequest(String url, String accessToken, ContentType contentType, 
			ResultMatcher... matchers) throws Exception {
		MockHttpServletRequestBuilder builder = delete(url);
		builder.header(\"Authorization\", \"Bearer \" + accessToken);
		executeRequest(builder, contentType, null, matchers);
	}"

	else 
	baseTest+="
	@Before
  public void setup() {
    this.mockMvc = MockMvcBuilders.webAppContextSetup(this.wac).build();
  }
	
	// Custom AccessToken implementation if any, goes here!!
	//protected String generateJWTToken() {}
	"
fi

	baseTest+="    
	public static byte[] convertObjectToJsonBytes(Object object) throws IOException {
    ObjectMapper mapper = new ObjectMapper();
    //mapper.setSerializationInclusion(JsonInclude.Include.NON_NULL);
    return mapper.writeValueAsBytes(object);
  }
  
  private void executeRequest(MockHttpServletRequestBuilder builder, ContentType contentType, 
										byte[] content, ResultMatcher... matchers) throws Exception{
  		if(contentType == ContentType.JSON){
  		builder.contentType(new MediaType(MediaType.APPLICATION_JSON.getType(), MediaType.APPLICATION_JSON.getSubtype(), Charset.forName(\"utf8\")));
  		}
  		if(content != null){
  			builder.content(content);
  		}
  		ResultActions results = mockMvc.perform(builder);
    	for(ResultMatcher matcher: matchers){
    		results.andExpect(matcher);  
    	} 
  }
  
	  public void executeGetRequest(String url, ContentType contentType, 
  								ResultMatcher... matchers) throws Exception{
​
		MockHttpServletRequestBuilder builder = get(url);
		executeRequest(builder, contentType, null, matchers);
	}
  

  public void executePostRequest(String url, ContentType contentType, 
									byte[] content, ResultMatcher... matchers) throws Exception{
		MockHttpServletRequestBuilder builder = post(url);
		executeRequest(builder, contentType, content, matchers);
	}
  
	  public void executePutRequest(String url, ContentType contentType, 
									byte[] content, ResultMatcher... matchers) throws Exception{
		MockHttpServletRequestBuilder builder = put(url);
		executeRequest(builder, contentType, content, matchers);
	}

		public void executeDeleteRequest(String url, ContentType contentType, 
			ResultMatcher... matchers) throws Exception {
		MockHttpServletRequestBuilder builder = delete(url);
		executeRequest(builder, contentType, null, matchers);
	}" 
	
	echo "$baseTest" >> "${dir}/BaseTest.java"

	dir="${dir}/controller"
	mkdir -p ${dir}

	echo -e "Don't forget to write this down into the application.properties file in the test/resources directory\n
\033[1;32m	\tspring.jpa.hibernate.ddl-auto=create

	\tspring.datasource.url=jdbc:h2:mem:db;DB_CLOSE_ON_EXIT=FALSE
	\tspring.datasource.username=sa
	\tspring.datasource.password=sa
	\tspring.jpa.database-platform=org.hibernate.dialect.H2Dialect
	\tspring.h2.console.enabled=true

	\tspring.datasource.driverClassName=org.h2.Driver"
fi

# Line Creator Functions
function headerLine(){
echo "		MockHttpServletRequestBuilder builder = $1(\"$2\")$3;

		executeRequest(builder, ContentType.JSON, $4, $5);" 
} 

function requestAuthWithNoBody(){
  echo "     		execute$1Request(\"$2\", token, ContentType.JSON, $3);"
}

function requestWithoutAuthAndBody(){
  echo "     		execute$1Request(\"$2\", ContentType.JSON, $3);"
}

function requestAuth(){
  echo "     		execute$1Request(\"$2\", token, ContentType.JSON, $3, $4);"
}

function requestWithoutAuth(){
  echo "     		execute$1Request(\"$2\", ContentType.JSON, $3, $4);"
}

#Create file and add basic imports along with 
re=0
jq -c '.functions[].fileName' $1 | while read i; do
    fileName=$(eval echo $i)
	[ $fileName = "null" ] && { echo -e "\033[1;31mfileName key is missing from json. Exiting..."; exit 1; }
    [[ $fileName == *Test ]] && fileName="$fileName" || fileName="${fileName}Test"
    touch "${dir}/${fileName}.java"
    echo "package ${package};

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.Test;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

import ${package}.ApplicationConfig;
import ${package}.BaseTest;
import ${package}.ContentType;

public class ${fileName} extends BaseTest 
{
">> "${dir}/${fileName}.java"	

	#Start Adding Tests
	ts=0
	max_ts=$(jq -r ".functions[${re}].tests | length" $1)
	jq -r ".functions[${re}].tests[${ts}]" $1 | while [ "$ts" -lt "$max_ts" ]; do
		functionName=$(jq -r ".functions[${re}].tests[${ts}].functionName" $1)
		functionName=$(eval echo $functionName)
			[ $functionName = "null" ] && { echo -e "\033[1;31mfunctionName key inside ${fileName} -> tests is missing in json. Exiting..."; exit 1; }
	
		auth=$(jq -r ".functions[${re}].tests[${ts}].auth // false" $1)
		if $auth; then
			authData=$(jq -r ".functions[${re}].tests[${ts}].authData // \"default\"" $1)
			if [ $authData == "default" ]; then
			  authData="ApplicationConfig.DEFAULT_NAME, ApplicationConfig.DEFAULT_PASS"
			else
			  authData=$(echo \"$authData\" | sed -e 's/;/\",\"/g')
			fi			
		fi

		type=$(jq -r ".functions[${re}].tests[${ts}].type" $1)
		type=$(eval echo $type | tr '[:lower:]' '[:upper:]')
			[ $type = "null" ] && { echo -e "\033[1;31mtype key inside ${fileName} -> tests is missing in json. Exiting..."; exit 1; }

		endpoint=$(jq -r ".functions[${re}].tests[${ts}].endpoint" $1)
			[ $endpoint = "null" ] && { echo -e "\033[1;31mendpoint key inside ${fileName} -> tests is missing in json. Exiting..."; exit 1; }

		result=$(jq -r ".functions[${re}].tests[${ts}].result" $1)
		result=$(echo $result | cut -d'.' -f2- | sed -r 's/(^|_)([A-Z])/\L\2/g' | sed -E 's/([[:lower:]])|([[:upper:]])/\U\1\L\2/g')
		result=$(echo "status().is$result()")
			[ $result = "null" ] && { echo -e "\033[1;31mresult key inside ${fileName} -> tests is missing in json. Exiting..."; exit 1; }

		headers=$(jq -r ".functions[${re}].tests[${ts}].headers // false" $1)
		enter=$'\n'
		tab=$'\t\t\t\t'

		if $headers; then
		  if $auth; then
		  	headerInfo=""
		    headerInfo+="$enter$tab.header(\"Authorization\", \"Bearer \" + token)"
		    hs=0	
		    max_hs=$(jq -r ".functions[${re}].tests[${ts}].headersData | length" $1)
		    while [ "$hs" -lt "$max_hs" ]; do
				headerKey=$(jq -r ".functions[${re}].tests[${ts}].headersData[${hs}].key" $1)
				headerValue=$(jq -r ".functions[${re}].tests[${ts}].headersData[${hs}].value" $1)
				[[ $headerValue == *[{}\(]*[\)] ]] && headerValue=$headerValue || headerValue=\"$headerValue\"
		    	headerInfo+="$enter$tab.header(\"$headerKey\", $headerValue)"
			hs=$((hs+1))
		    done < <(jq -r ".functions[${re}].tests[${ts}].headersData" $1)
		
		  else
		    hs=0	
		    max_hs=$(jq -r ".functions[${re}].tests[${ts}].headersData | length" $1)
		    headerInfo=""
		    while [ "$hs" -lt "$max_hs" ]; do
				headerKey=$(jq -r ".functions[${re}].tests[${ts}].headersData[${hs}].key" $1)
				headerValue=$(jq -r ".functions[${re}].tests[${ts}].headersData[${hs}].value" $1)
				[[ $headerValue == *[{}\(]*[\)] ]] && headerValue=$headerValue || headerValue=\"$headerValue\"
		    	headerInfo+="$enter$tab.header(\"$headerKey\", $headerValue)"
			hs=$((hs+1))
		    done < <(jq -r ".functions[${re}].tests[${ts}].headersData" $1)
		  fi
		fi

		data=$(jq -r ".functions[${re}].tests[${ts}].data // \"\"" $1)
		if [ ! -z "$data" ] 
		then
			#After POST line use echo "String data = $data; | " >>
			newdata=$(echo $data |\
				perl -pe 's/{/{\n/; s/}/\n}/; s/, /,\n/g; ' |\
				perl -0pe 's/"/\\"/g; s/\n/\\n" + \n/g; s/^/"/gm; s/^"/\t\t\t\t"/gm; s/^\t\t\t\t"/"/; s/\}\\n.*$/}"/')

		else
			newdata=\"\"
		fi		

		echo "	@Test
	public void ${functionName}() throws Exception {
				" >> "${dir}/${fileName}.java"	

		if $auth; then
		  echo "		String token = obtainAccessToken($authData, 
						ApplicationConfig.OAUTH_CLIENT_ID,ApplicationConfig.OAUTH_CLIENT_SECRET);
" >> "${dir}/${fileName}.java"
		fi

		case $type in
			GET)
				if $headers; then
					echo "$(headerLine get $endpoint "$headerInfo" null $result)" >> "${dir}/${fileName}.java"
				elif $auth; then
					echo "$(requestAuthWithNoBody Get $endpoint $result)" >> "${dir}/${fileName}.java"
				else
					echo "$(requestWithoutAuthAndBody Get $endpoint $result)" >> "${dir}/${fileName}.java"
				fi
				;;	
			POST)	
				echo "		String data = $newdata;
							" >> "${dir}/${fileName}.java"
				if $headers; then
					echo "$(headerLine post $endpoint "$headerInfo" "data.getBytes()" $result)" >> "${dir}/${fileName}.java"
				elif $auth; then
					echo "$(requestAuth Post $endpoint "data.getBytes()" $result)" >> "${dir}/${fileName}.java"
				else			
					echo "$(requestWithoutAuth Post $endpoint "data.getBytes()" $result)" >> "${dir}/${fileName}.java"
				fi
				;;	
			PUT)	
				echo "		String data = $newdata;
							" >> "${dir}/${fileName}.java"
				if $headers; then
					echo "$(headerLine put $endpoint "$headerInfo" "data.getBytes()" $result)" >> "${dir}/${fileName}.java"
				elif $auth; then
					echo "$(requestAuth Put $endpoint "data.getBytes()" $result)" >> "${dir}/${fileName}.java"
				else			
					echo "$(requestWithoutAuth Put $endpoint "data.getBytes()" $result)" >> "${dir}/${fileName}.java"
				fi
				;;
			DELETE)	
				echo "		String data = $newdata;
							" >> "${dir}/${fileName}.java"
				if $headers; then
					echo "$(headerLine delete $endpoint "$headerInfo" null $result)" >> "${dir}/${fileName}.java"
				elif $auth; then
					echo "$(requestAuthWithNoBody Delete $endpoint $result)" >> "${dir}/${fileName}.java"
				else			
					echo "$(requestWithoutAuthAndBody Delete $endpoint $result)" >> "${dir}/${fileName}.java"
				fi
				;;
		esac
	echo "	}" >> "${dir}/${fileName}.java"
	ts=$((ts+1))
	done	
echo "}" >> "${dir}/${fileName}.java"
re=$((re+1))
done

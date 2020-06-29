package test

import (
	"encoding/json"
	"fmt"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/sqs"
	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"log"
	"testing"
	"time"
)

// TODO: update to use api key so it can get a 200 from he api
func TestLogCanBeSubmittedToApi(t *testing.T) {
	//t.Parallel()

	terraformOptions := SpinUpTheModule(t)
	defer terraform.Destroy(t, terraformOptions)

	apiKey := terraform.Output(t, terraformOptions, "custom_logging_api_key")

	WriteAMessageToTheApiAndExpect(t, terraformOptions, 200, apiKey)
	VerifyThatMessageWasPlacedOnQueue(t, terraformOptions)
}

func TestLogCanotBeSubmittedToApiWithoutApiKey(t *testing.T) {
	//t.Parallel()

	terraformOptions := SpinUpTheModule(t)
	defer terraform.Destroy(t, terraformOptions)

	//TODO: is 403 right here? or do we want to persuade aws to give us a 401?
	WriteAMessageToTheApiAndExpect(t, terraformOptions, 403, "")
}

func VerifyThatMessageWasPlacedOnQueue(t *testing.T, terraformOptions *terraform.Options) {
	sess, _ := session.NewSession(&aws.Config{Region: aws.String("eu-west-2")})

	svc := sqs.New(sess)

	qURL := terraform.Output(t, terraformOptions, "custom_log_queue_url")

	result, err := svc.ReceiveMessage(&sqs.ReceiveMessageInput{
		AttributeNames: []*string{
			aws.String(sqs.MessageSystemAttributeNameSentTimestamp),
		},
		MessageAttributeNames: []*string{
			aws.String(sqs.QueueAttributeNameAll),
		},
		QueueUrl:            &qURL,
		MaxNumberOfMessages: aws.Int64(1),
		VisibilityTimeout:   aws.Int64(20),  // 20 seconds
		WaitTimeSeconds:     aws.Int64(0),
	})

	if err != nil {
		fmt.Println("Error", err)
		return
	}

	if len(result.Messages) == 0 {
		t.Fatalf("Received no messages")
		t.Fail()
		return
	}

	expectedMessageBodyBytes, _ := json.Marshal(map[string]string{
		"foo": "bar",
	})

	expectedMessageBody := string(expectedMessageBodyBytes)


	messageBody := reformatJsonString(*result.Messages[0].Body)


	if messageBody != expectedMessageBody {
		log.Println("expected message:")
		log.Println(expectedMessageBody)
		log.Println("but got:")
		log.Println(messageBody)
		t.Fail()
	}
}

func reformatJsonString(theThing string) string {
	var messageBodyMap map[string]interface{}
	err := json.Unmarshal([]byte(theThing), &messageBodyMap)

	if err != nil {
		log.Println("unable to reformat json")
		log.Println(err.Error())
		log.Println(theThing)
	}

	messageBody, _ := json.Marshal(messageBodyMap)

	return string(messageBody)
}

func WriteAMessageToTheApiAndExpect(t *testing.T, terraformOptions *terraform.Options, code int, apiKey string) {
	loggingEndpointPath := terraform.Output(t, terraformOptions, "logging_endpoint_path")

	requestBody, _ := json.Marshal(map[string]string{
		"foo": "bar",
	})

	_, err := http_helper.HTTPDoWithRetryE(t,
		"POST",
		loggingEndpointPath,
		requestBody,
		map[string]string{"Content-Type": "application/json", "X-API-KEY": apiKey},
		code,
		5,
		time.Second * 5,
		nil,
	)

	if err != nil {
		t.Fatalf("Api did not return code '%d'", code)
		t.Fail()
	}
}

func SpinUpTheModule(t *testing.T) *terraform.Options {
	terraformOptions := &terraform.Options{
		// Set the path to the Terraform code that will be tested.
		TerraformDir: "../modules/logging",
		Vars:         map[string]interface{}{"prefix": "david-test", "vpc_id": ""},
	}

	// Run "terraform init" and "terraform apply". Fail the test if there are any errors.
	terraform.InitAndApplyAndIdempotent(t, terraformOptions)
	return terraformOptions
}

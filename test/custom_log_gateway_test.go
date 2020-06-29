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

func TestLogCanBeSubmittedToApi(t *testing.T) {
	t.Parallel()

	terraformOptions := SpinUpTheModule(t)
	defer terraform.Destroy(t, terraformOptions)

	WriteAMessageToTheApi(t, terraformOptions)
	VerifyThatMessageWasPlacedOnQueue(t, terraformOptions)
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

func WriteAMessageToTheApi(t *testing.T, terraformOptions *terraform.Options) {
	loggingEndpointPath := terraform.Output(t, terraformOptions, "logging_endpoint_path")

	requestBody, _ := json.Marshal(map[string]string{
		"foo": "bar",
	})

	http_helper.HTTPDoWithRetry(t,
		"POST",
		loggingEndpointPath,
		requestBody,
		map[string]string{"Content-Type": "application/json"},
		200,
		5,
		time.Second * 5,
		nil,
	)
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

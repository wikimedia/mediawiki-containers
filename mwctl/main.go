package main

import (
	"fmt"
	"gopkg.in/alecthomas/kingpin.v2"
	"io"
	"log"
	"os"
	"os/exec"
)

var (
	app = kingpin.New("mwctl", "Install and drive the mediawiki-containers development environment.")

	devel       = app.Command("develop", "Prepare a service for development")
	devServices = devel.Arg("service", "Name of service(s) to develop").Required().Strings()

	apply         = app.Command("apply", "Apply a change in the dev environment")
	applyServices = apply.Arg("service", "Name of services(s) to apply changes").Required().Strings()

	test         = app.Command("test", "Test a service in a fresh container.")
	testServices = test.Arg("service", "Name of service(s) whose changes you would like to test").Required().Strings()
)

func applyConfig(config string) ([]byte, error) {
	cmd := exec.Command("kubectl", "apply", "-f", "-")
	stdin, _ := cmd.StdinPipe()

	go func() {
		defer stdin.Close()
		io.WriteString(stdin, config)
	}()

	return cmd.CombinedOutput()
}

func main() {
	switch kingpin.MustParse(app.Parse(os.Args[1:])) {
	case devel.FullCommand():
		fmt.Println("devel")
		for _, service := range *devServices {
			fmt.Println("  " + service)
		}

	case apply.FullCommand():
		out, err := exec.Command("minikube", "ip").Output()
		if err != nil {
			log.Fatal(err)
		}
		fmt.Printf("The IP is: %s", out)

	case test.FullCommand():
		fmt.Println("test")
	}
}

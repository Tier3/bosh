package action

import (
	"reflect"
	"encoding/json"
	"strconv"
	bosherr "bosh/errors"
)


type Runner interface {
	Run(action Action, payload []byte) (value interface{}, err error)
}

func NewRunner() Runner {
	return concreteRunner{}
}

type concreteRunner struct {

}

func (r concreteRunner) Run(action Action, payloadBytes []byte) (value interface{}, err error) {
	type payloadType struct {
		Arguments []interface{} `json:"arguments"`
	}
	payload := payloadType{}

	err = json.Unmarshal(payloadBytes, &payload)
	if err != nil {
		err = bosherr.WrapError(err, "Unmarshalling payload arguments to interface{} types")
	    return
	}

	actionValue := reflect.ValueOf(action)
	runMethodValue := actionValue.MethodByName("RunWithoutPayload")

	//	if runMethodValue.Kind() != reflect.Func {
	//		err = errors.New("Run method not found")
	//		return
	//	}

	runMethodType := runMethodValue.Type()

	numberOfArgs := runMethodType.NumIn()
	var methodArgs = make([]reflect.Value, numberOfArgs)

	for i := 0; i < numberOfArgs; i++ {
		argType := runMethodType.In(i)
		argFromPayload := payload.Arguments[i]

		var rawArgBytes []byte
		rawArgBytes, err = json.Marshal(argFromPayload)
		if err != nil {
		    return
		}

		argValuePtr := reflect.New(argType)

		var intValue int

		switch argType.Kind() {

		case reflect.String:
			stringValue := string(rawArgBytes)
			methodArgs[i] = reflect.ValueOf(stringValue)

		case reflect.Int:
			intValue, err = strconv.Atoi(string(rawArgBytes))
			if err != nil {
				err = bosherr.WrapError(err, "Converting action argument to int")
			    return
			}
			methodArgs[i] = reflect.ValueOf(intValue)

		default:
			argPtr := argValuePtr.Interface()
			err = json.Unmarshal(rawArgBytes, argPtr)
			if err != nil {
				err = bosherr.WrapError(err, "Unmarshalling action argument")
				return
			}

			methodArgs[i] = reflect.Indirect(argValuePtr)
		}
	}

	values := runMethodValue.Call(methodArgs)

	errValue := values[1]
	if !errValue.IsNil() {
		errorValues := errValue.MethodByName("Error").Call([]reflect.Value{})
		err = bosherr.New(errorValues[0].String())
		return
	}

	value = values[0].Interface()
	return
}

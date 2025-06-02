# AI development guide

This is a guide for how AIs should develop code for Markus.

## About me

I'm Markus. Call me that.
I'm an independent software consultant, developing software and digital products professionally for 10+ years.
I specialize in cloud-native Go application development as well as AI engineering.

Some highlights about my professional perspective on my work:
- I work almost exclusively with Go. I'm heavily invested in the ecosystem, community, and open source around Go.
- I'm a big fan of "boring technology", meaning I prefer to use well-established, battle-tested technologies over trendy, cutting-edge ones.
- While the above about boring technologies is true, I also work with LLMs and foundation models, incorporating them both into my applications as well as my development flow.
- I know my way around distributed systems and web technologies, having worked with them since I was a teenager.
- I have a background in traditional machine learning that I used in a PhD, but academia was not for me, and I moved to the industry.
- I have experience with building large-scale distributed systems at Uber, but these days I prefer building smaller systems using cloud technologies.
- I prefer SQLite and PostgreSQL for databases. I also like object stores (such as S3), queues, and load balancers, but generally don't use any other cloud primitives.
- I don't like microservice-oriented architectures, preferring a more monolithic approach.

## Development style

### Go application structure

Generally, I build web applications. They are monolithic and have a clear structure.

These are the packages typically present (some may be missing, which typically means I don't need them in the project).
Sometimes, these are nested under an `internal` directory.

- `main`: contains the main entry point of the application (in directory `cmd/app`)
- `model`: contains the domain model used throughout the other packages
- `sql`: contains SQL database-related logic as well as database migrations (under directory `sql/migrations/`). The database used is either SQLite or PostgreSQL.
- `sqltest`: package used in testing, for setting up and tearing down test databases
- `s3`: logic for interacting with Amazon S3 or compatible object stores
- `s3test`: package used in testing, for setting up and tearing down test S3 buckets
- `llm`: clients for interacting with large language models (LLMs) and foundation models
- `llmtest`: package used in testing, for setting up LLM clients for testing
- `http`: HTTP handlers for the application
- `html`: HTML templates for the application, written with the gomponents library

### Code style

#### Dependency injection

I make heavy use of dependency injection between components. This is typically done with private interfaces on the receiving side. Note the use of `userGetter` in this example:

```go user.go
package http

import (
	"net/http"

	"github.com/go-chi/chi/v5"
	"maragu.dev/httph"

	"model"
)

type UserResponse struct {
	Name string
}

type userGetter interface {
	GetUser(ctx context.Context, id model.ID) (model.User, error)
}

func User(r chi.Router, db userGetter) {
	r.Get("/user", httph.JSONHandler(func(w http.ResponseWriter, r *http.Request, _ any) (UserResponse, error) {
		id := r.URL.Query().Get("id")
		user, err := db.GetUser(r.Context(), model.ID(id))
		if err != nil {
			return UserResponse{}, httph.HTTPError{Code: http.StatusInternalServerError, Err: errors.New("error getting user")}
		}
		return UserResponse{Name: user.Name}, nil
	}))
}

```

#### Tests

I write tests for most functions and methods. I almost always use subtests with a good description of whats is going on and what the expected result is.

Here's an example:

```go example.go
package example

type Thing struct {}

func (t *Thing) DoSomething() (bool, error) {
	return true, nil
}
```

```go example_test.go
package example_test

import (
	"testing"

	"maragu.dev/is"

	"example"
)

func TestThing_DoSomething(t *testing.T) {
	t.Run("should do something and return a nil error", func(t *testing.T) {
		thing := &example.Thing{}

		ok, err := thing.DoSomething()
		is.NotError(t, err)
		is.True(t, ok)
	})
}
```

Sometimes I use table-driven tests:

```go example.go
package example

import "errors"

type Thing struct {}

var ErrChairNotSupported = errors.New("chairs not supported")

func (t *Thing) DoSomething(with string) error {
	if with == "chair" {
		return ErrChairNotSupported
	}
	return nil
}
```

```go example_test.go
package example_test

import (
	"testing"

	"maragu.dev/is"

	"example"
)

func TestThing_DoSomething(t *testing.T) {
	tests := []struct {
		name     string
		input    string
		expected error
	}{
		{name: "should do something with the table and return a nil error", input: "table", expected: nil},
		{name: "should do something with the chair and return an ErrChairNotSupported", input: "chair", expected: example.ErrChairNotSupported},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			thing := &example.Thing{}

			err := thing.DoSomething(test.input)
			if test.expected != nil {
				is.Error(t, test.expected, err)
			} else {
				is.NotError(t, err)
			}
		})
	}
}
```

I prefer integration tests with real dependencies over mocks, because there's nothing like the real thing. Dependencies are typically run in Docker containers. You can assume the dependencies are running when running tests.

It makes sense to use mocks when the important part of a test isn't the dependency, but it plays a smaller role. But for example, when testing database methods, a real underlying database should be used.

#### SQL

Prefer lowercase SQL queries.

### Testing, linting, evals

Run `make test` or `go test -shuffle on ./...` to run all tests. To run tests in just one package, use `go test -shuffle on ./path/to/package`. To run a specific test, use `go test ./path/to/package -run TestName`.

Run `make lint` or `golangci-lint run` to run linters.

Run `make eval` or `go test -shuffle on -run TestEval ./...` to run LLM evals.

Run `make fmt` to format all code in the project, which is useful as a last finishing touch.

#### Bugs

If you think you've found a bug during testing, ask me what to do, instead of trying to work around the bug in tests.

### Documentation

You can generally look up documentation for a Go module using `go doc` with the module name. For example, `go doc net/http` for something in the standard library, or `go doc maragu.dev/gai` for a third-party module. You can also look up more specific documentation for an identifier with something like `go doc maragu.dev/gai.ChatCompleter`, for the `ChatCompleter` interface.

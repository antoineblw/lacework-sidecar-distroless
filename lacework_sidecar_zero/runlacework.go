package main

import (
    "os"
    "os/exec"
    "bufio"
    "log"
    "net/http"
    "time"
)

func testLacework() bool {
   resp, err := http.Get("https://api.lacework.net")
   var _ = resp
   if err != nil {
      return false;
   }
   return true;
}

func execDataCollector(vlog log.Logger) {
    vlog.Print("Launching Lacework datacollector")

    // The datacollector must be run from /var/lib/lacework/
    err := os.Mkdir("/var/lib/lacework", 0755)
    if err != nil {
          vlog.Fatal(err)
    }
    os.Symlink("/lacework/datacollector", "/var/lib/lacework/datacollector")
    //FIXME
    os.Mkdir("/lib", 0755)
    os.Symlink("/lacework/lib/ld-musl-x86_64.so.1", "/lib/ld-musl-x86_64.so.1")

    cmd := exec.Command("/var/lib/lacework/datacollector")

    stdout, err := cmd.StdoutPipe()
    stderr, err := cmd.StderrPipe()

    if err != nil {
          vlog.Fatal(err)
    }

    if err := cmd.Start(); err != nil {
          vlog.Fatal(err)
    }

    in := bufio.NewScanner(stdout)
    in_err := bufio.NewScanner(stderr)

    // Now we just loop forever, redirect datacollector stdout to our log/stdout
    for {
       for in.Scan() {
	       vlog.Printf("out: %s", in.Text())
       }
       for in_err.Scan() {
	       vlog.Printf("err: %s", in_err.Text())
       }

       time.Sleep(1 * time.Second)
    }
}

func execMonitoredProcess(val string, vlog log.Logger) {
    vlog.Printf("Launching RUN_CMD Process", val)

    cmd := exec.Command(val)

    stdout, err := cmd.StdoutPipe()

    if err != nil {
          vlog.Fatal(err)
    }

    if err := cmd.Start(); err != nil {
          vlog.Fatal(err)
    }

    in := bufio.NewScanner(stdout)

    // Now we just loop forever, redirect app stdout to our log/stdout
    for {
       for in.Scan() {
         vlog.Printf(in.Text())
       }

       time.Sleep(1 * time.Second)
    }
}

func main() {
   logger := log.New(os.Stdout, "", 0)
   // If RUN_CMD is not defined we don't run. This is the default case and what happens when we're run
   // in fargate is that we just terminate.
   val, ok := os.LookupEnv("RUN_CMD")
   if (!ok) {
     logger.Printf("No RUN_CMD defined, exit")
     return;
   }

   logger.Printf("Loading Lacework")
   // Parameters

   // Test connectivity to lacework.
   if (!testLacework()) {
     logger.Printf("Connectivity to Lacework problem - exiting")
     return;
   }

   // Launch Lacework datacollector
   go execDataCollector(*logger)

   // RUN_CMD env parm will be what we spawn last.
   go execMonitoredProcess(val, *logger)

   for {
	   //Do nothing here, in theory should wait and monitor health of sub processes.
	  time.Sleep(8 * time.Second)
   }
}

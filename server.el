(require 'web-server)

;; (ws-start				; Working
;;  (lambda (request)
;;    (with-slots (process headers) request
;;      (ws-response-header process 200 '("Content-type" . "text/plain"))
;;      (process-send-string process "hello world")))
;;  9000)


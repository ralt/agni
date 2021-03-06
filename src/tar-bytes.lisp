(in-package #:agni)


(defconstant +name-offset+ 0)
(defconstant +mode-offset+ 100)
(defconstant +uid-offset+ 108)
(defconstant +gid-offset+ 116)
(defconstant +size-offset+ 124)
(defconstant +mtime-offset+ 136)
(defconstant +chksum-offset+ 148)
(defconstant +typeflag-offset+ 156)
(defconstant +linkname-offset+ 157)
(defconstant +magic-offset+ 257)
(defconstant +version-offset+ 263)
(defconstant +uname-offset+ 265)
(defconstant +gname-offset+ 297)
(defconstant +devmajor-offset+ 329)
(defconstant +devminor-offset+ 337)
(defconstant +prefix-offset+ 345)
(defconstant +content-offset+ 512)

(defmethod tar-bytes-name ((f file) &key)
  "100 bytes"
  (vector-add (string-to-bytes (tar-path f))
              (tar-bytes-headers f) +name-offset+))

(defmethod tar-bytes-mode ((f file) &key)
  "8 bytes"
  (vector-add-integer f (mode f) +mode-offset+))

(defmethod tar-bytes-uid ((f file) &key)
  "8 bytes"
  (vector-add-integer f (uid f) +uid-offset+))

(defmethod tar-bytes-gid ((f file) &key)
  "8 bytes"
  (vector-add-integer f (gid f) +gid-offset+))

(defmethod tar-bytes-size ((f file) &key)
  "12 bytes"
  (vector-add (string-to-bytes
               (format nil "~11,'0o" (integer-to-ascii-octal (size f))))
              (tar-bytes-headers f)
              +size-offset+))

(defmethod tar-bytes-mtime ((f file) &key)
  "12 bytes"
  (vector-add (string-to-bytes
               (format nil "~11,'0o" (integer-to-ascii-octal (mtime f))))
              (tar-bytes-headers f)
              +mtime-offset+))

(defmethod tar-bytes-chksum ((f file) &key)
  "8 bytes"
  (vector-add (string-to-bytes "        ")
              (tar-bytes-headers f)
              +chksum-offset+))

(defmethod tar-bytes-typeflag ((f file) &key)
  "1 byte"
  (let ((mode (mode f)))
    (vector-add (string-to-bytes
                 (write-to-string (cond
                                    ((is-reg mode) 0)
                                    ;; is-hard-link is NIY
                                    ((is-lnk mode) 2)
                                    ((is-chr mode) 3)
                                    ((is-blk mode) 4)
                                    ((is-dir mode) 5)
                                    ((is-fifo mode) 6))))
                (tar-bytes-headers f)
                +typeflag-offset+)))

(defmethod tar-bytes-linkname ((f file) &key)
  "100 bytes
Regular files only for now, so nothing")

(defmethod tar-bytes-magic ((f file) &key)
  "6 bytes"
  (vector-add (string-to-bytes "ustar ")
              (tar-bytes-headers f)
              +magic-offset+))

(defmethod tar-bytes-version ((f file) &key)
  "2 bytes"
  (vector-add (string-to-bytes " ")
              (tar-bytes-headers f)
              +version-offset+))

(defmethod tar-bytes-uname ((f file) &key)
  "32 bytes"
  (vector-add (string-to-bytes (username-from-uid (uid f)))
              (tar-bytes-headers f)
              +uname-offset+))

(defmethod tar-bytes-gname ((f file) &key)
  "32 bytes"
  (vector-add (string-to-bytes (groupname-from-gid (gid f)))
              (tar-bytes-headers f)
              +gname-offset+))

(defmethod tar-bytes-devmajor ((f file) &key)
  "8 bytes
Empty for now")

(defmethod tar-bytes-devminor ((f file) &key)
  "8 bytes
Empty for now")

(defmethod tar-bytes-prefix ((f file) &key)
  "155 bytes
Empty for now")

(defmethod tar-bytes-pad ((f file) &key)
  "12 bytes
Voluntarily keep it empty")

(defmethod tar-bytes-content ((f file) &key)
  (with-open-file (stream (path f) :element-type '(unsigned-byte 8))
    (let ((bytes (make-array (size f) :element-type '(unsigned-byte 8))))
      (read-sequence bytes stream)
      bytes)))

(defmethod tar-bytes-calculate-checksum ((f file) &key)
  (vector-add (append
               (string-to-bytes
                (format nil "~6,'0o"
                        (calculate-checksum
                         (tar-bytes-headers f))))
               '(0 20))
              (tar-bytes-headers f)
              +chksum-offset+))

(defun calculate-checksum (headers)
  (reduce #'+ headers))

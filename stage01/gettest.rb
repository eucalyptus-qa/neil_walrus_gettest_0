#!/usr/bin/ruby
# Author: Neil Soman <neil@eucalyptus.com>

require 'rubygems'
require 'right_aws'

def log_success(message)
    puts "[TEST_REPORT]\t" + message
end

def log_failure(message)
    puts "[TEST_REPORT]\tFAILED: " + message
    exit(1)
end

def generate_string( len )
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    generate_string = ""
    1.upto(len) { |i| generate_string << chars[rand(chars.size-1)] }
    return generate_string
end

def put_object(bucket, objectname)
    key = RightAws::S3::Key.create(bucket, objectname)
    key.data = 'werignrewngorwengiwrenginerwignioerwngirwengvndfrsignoreihgioerqngoirengoinianroignoignriaongr2202fg3q4gwng'
    key.put 
    log_success("Adding object: %s" % objectname)
    return key
end

def get_object(bucket, objectname)
    key = RightAws::S3::Key.create(bucket, objectname)
    key.get
    log_success("Last Modified: %s" % key.last_modified + "Owner: %s" % key.owner + "Size: %s" % key.size)
end

def delete_object(key)
    if key.delete
	log_success("Object %s deleted" % key.name)
    else
	log_failure("Unable to delete object %s" % key.name)
    end
end

def delete_bucket(bucket)
begin
    if bucket.delete(true)
        log_success("Bucket %s deleted" % bucket.name)
    else
	log.success("Unable to delete bucket: %s" % bucket.name)
    end
rescue RightAws::AwsError
    log_failure("Error creating bucket %s" % bucketname)
end
end

def setup_ec2
    return RightAws::Ec2.new(ENV['EC2_ACCESS_KEY'],ENV['EC2_SECRET_KEY'])
end

def setup_s3
    s3 = RightAws::S3.new(aws_access_key_id=ENV['EC2_ACCESS_KEY'], aws_secret_access_key=ENV['EC2_SECRET_KEY'], params={:multi_thread => true})
end

def screen_dump(string)
    log_success("******%s******" % string)
end

def test0(s3)
begin
    screen_dump('Get Object Extended')
    old_time = "%s" % (Time.now - 8640).httpdate()
    bucketname = 'test_bucket_%s' % generate_string(10)
    bucket = RightAws::S3::Bucket.create(s3, bucketname, true, 'public-read', :location => :us)
    log_success("Created bucket: %s" % bucketname)
    object = put_object(bucket, 'test_object_%s' % generate_string(10))
    screen_dump('If-None-Match')
    object.get(headers={'If-None-Match' => '232332'})
    screen_dump('If-Match')
    object.get(headers={'If-Match' => 'e8cfb7416bb84478c0b705753db307c0'})
    screen_dump('#1 Get Object: Range')
    range_get = "%s" % object.get(headers={'Range' => 'bytes=0-9'})
    if range_get.size != 10
        log_failure('#1 Get Object: Range return %s' % range_get.size)
    end
    screen_dump('#2 Get Object: Range')
    range_get = "%s" % object.get(headers={'Range' => 'bytes=0-'})
    if range_get.size != 107
        log_failure('#2 Get Object: Range return %s' % range_get.size)
    end
    screen_dump('#3 Get Object: Range')
    range_get = "%s" % object.get(headers={'Range' => 'bytes=-100'})
    if range_get.size != 101
        log_failure('#3 Get Object: Range return %s' % range_get.size)
    end
    time = "%s" % (Time.now + 8640).httpdate()
    screen_dump('If-Unmodified-Since: ' + time)
    object.get(headers={'If-Unmodified-Since' => time})
    screen_dump('If-Modified-Since: ' + old_time)
    object.get(headers={'If-Modified-Since' => old_time})
    delete_object(object)
   
    #key with path char
    screen_dump('Put/Get Object Path Chars')
    object = put_object(bucket, 'test_object_%s/keypart0/keypart1' % generate_string(10))
    object.get()
    delete_object(object)

    delete_bucket(bucket)
rescue RightAws::AwsError
    log_failure("test0 failed")
end
end

s3 = setup_s3
test0(s3)

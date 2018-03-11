import vibe.vibe;
import tinyredis;
import std.process : environment;
import std.datetime : Clock;

Redis redis;

void main()
{
	redis = new Redis(environment.get("REDIS_HOST", "localhost"), 6379);
	redis.send("SET name Redis");
	new HTTPServerSettings("0.0.0.0:8888").listenHTTP(&hello);
	runApplication();
}

void hello(HTTPServerRequest req, HTTPServerResponse res)
{
	auto name = redis.send("GET name").toString();
	auto time = Clock.currTime();
	res.writeBody("Hello %s!\nCurrent time: %s".format(name, time));
}

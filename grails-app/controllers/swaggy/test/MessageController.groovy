package swaggy.test

import com.wordnik.swagger.annotations.Api
import com.wordnik.swagger.annotations.ApiImplicitParam
import com.wordnik.swagger.annotations.ApiImplicitParams
import com.wordnik.swagger.annotations.ApiOperation

@Api(value = "swaggy-test")
class MessageController {

    @ApiOperation(value = "Says Hello World",
      produces='text/plain')
    def index() {
        render "Hello World ${new Date()}!"
    }
}

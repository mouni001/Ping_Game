-- MyBall Class --

MyBall = Class{} 

function MyBall:init(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width  
    self.height = height
    self.dy = math.random(2) == 1 and -100 or 100
    self.dx = math.random(2) == 1 and math.random(-80, -100) or math.random(80, 100)
end

function MyBall:collides(paddle)
    if self.x > paddle.x + paddle.width or paddle.x > self.x + self.width then
        return false
    end

    if self.y > paddle.y + paddle.height or paddle.y > self.y + self.height then
        return false
    end 

    return true
end

function MyBall:reset()
    self.x = VIRTUAL_WIDTH / 2 - 2
    self.y = VIRTUAL_HEIGHT / 2 - 2
    self.dy = math.random(2) == 1 and -100 or 100
    self.dx = math.random(-50, 50)
end

function MyBall:update(dt)
    self.x = self.x + self.dx * dt
    self.y = self.y + self.dy * dt
end

function MyBall:render()
    love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)
end


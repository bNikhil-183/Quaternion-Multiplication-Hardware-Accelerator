#include <Wire.h>
#define MPU_ADDR 0x68

// Gyroscope raw data
float gx, gy, gz;

float dt = 0.01;

// Orientation quaternion (w, x, y, z)
struct Quaternion {
  float w, x, y, z;
} q = {1.0, 0.0, 0.0, 0.0};  // Initial orientation

// Received quaternion from FPGA
int16_t q0_i, q1_i, q2_i, q3_i;

void setup() {
  Wire.begin();
  Serial.begin(115200);

  Wire.beginTransmission(MPU_ADDR);
  Wire.write(0x6B);
  Wire.write(0);
  Wire.endTransmission();
}

void loop() {

  Wire.beginTransmission(MPU_ADDR);
  Wire.write(0x43);
  Wire.endTransmission(false);
  Wire.requestFrom(MPU_ADDR, 6);

  int16_t rawX = Wire.read() << 8 | Wire.read();
  int16_t rawY = Wire.read() << 8 | Wire.read();
  int16_t rawZ = Wire.read() << 8 | Wire.read();

  gx = rawX / 131.0;  // deg/sec
  gy = rawY / 131.0;
  gz = rawZ / 131.0;

  // Convert gyro to quaternion delta 
  float wx = radians(gx);
  float wy = radians(gy);
  float wz = radians(gz);

  Quaternion delta;
  delta.w = 0;
  delta.x = 0.5 * wx * dt;
  delta.y = 0.5 * wy * dt;
  delta.z = 0.5 * wz * dt;

  // Quaternion multiplication (q = q + q ⊗ delta)
  Quaternion qNew;
  qNew.w = q.w + (-delta.x * q.x - delta.y * q.y - delta.z * q.z);
  qNew.x = q.x + ( delta.x * q.w + delta.y * q.z - delta.z * q.y);
  qNew.y = q.y + (-delta.x * q.z + delta.y * q.w + delta.z * q.x);
  qNew.z = q.z + ( delta.x * q.y - delta.y * q.x + delta.z * q.w);

  // Normalize quaternion
  float norm = sqrt(qNew.w*qNew.w + qNew.x*qNew.x + qNew.y*qNew.y + qNew.z*qNew.z);
  q.w = qNew.w / norm;
  q.x = qNew.x / norm;
  q.y = qNew.y / norm;
  q.z = qNew.z / norm;

  //Send quaternion to FPGA 
  int16_t qw = q.w * 10000;
  int16_t qx = q.x * 10000;
  int16_t qy = q.y * 10000;
  int16_t qz = q.z * 10000;

  Serial.write((uint8_t*)&qw, 2);
  Serial.write((uint8_t*)&qx, 2);
  Serial.write((uint8_t*)&qy, 2);
  Serial.write((uint8_t*)&qz, 2);

  delay(10); 

  //Receive processed quaternion from FPGA 
  if (Serial.available() >= 8) {
    uint8_t buffer[8];
    for (int i = 0; i < 8; i++) {
      buffer[i] = Serial.read();
    }

    q0_i = (int16_t)(buffer[1] << 8 | buffer[0]);
    q1_i = (int16_t)(buffer[3] << 8 | buffer[2]);
    q2_i = (int16_t)(buffer[5] << 8 | buffer[4]);
    q3_i = (int16_t)(buffer[7] << 8 | buffer[6]);

    float qw_f = q0_i / 10000.0;
    float qx_f = q1_i / 10000.0;
    float qy_f = q2_i / 10000.0;
    float qz_f = q3_i / 10000.0;

    //Convert received quaternion back to gyro 
    float wx_r = 2 * (-qx_f * qw_f + qy_f * qz_f - qz_f * qy_f) / dt;
    float wy_r = 2 * (-qy_f * qw_f + qz_f * qx_f - qx_f * qz_f) / dt;
    float wz_r = 2 * (-qz_f * qw_f + qx_f * qy_f - qy_f * qx_f) / dt;

   
    Serial.print("Received Quaternion: ");
    Serial.print(q0_i); Serial.print(" ");
    Serial.print(q1_i); Serial.print(" ");
    Serial.print(q2_i); Serial.print(" ");
    Serial.println(q3_i);

    Serial.print("Back-converted Angular Velocity: ");
    Serial.print(degrees(wx_r)); Serial.print(" ");
    Serial.print(degrees(wy_r)); Serial.print(" ");
    Serial.println(degrees(wz_r));
  }
}
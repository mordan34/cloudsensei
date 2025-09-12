conn, err := grpc.Dial("ingest.cloudsensei.com:443", grpc.WithTransportCredentials(creds))
if err != nil {
    log.Fatalf("failed to connect: %v", err)
}
defer conn.Close()

client := pb.NewIngestServiceClient(conn)

// open stream
stream, err := client.StreamMetrics(context.Background())
if err != nil {
    log.Fatalf("could not open stream: %v", err)
}

// example batch
batch := &pb.MetricBatch{
    TenantId: "cust-123",
    Ts: time.Now().Format(time.RFC3339),
    Metrics: []*pb.Metric{
        {Name: "cpu_utilization", Value: 87.3, Labels: map[string]string{"region":"us-east-1"}},
    },
}

// send batch
if err := stream.Send(batch); err != nil {
    log.Fatalf("failed to send metrics: %v", err)
}

// receive ack
ack, err := stream.CloseAndRecv()
if err != nil {
    log.Fatalf("failed to receive ack: %v", err)
}
log.Printf("Server ack: %v", ack.Message)

#!/bin/bash
packer build -only=basis.amazon-ebs.template .
packer build -only=db.amazon-ebs.template .
packer build -only=app.amazon-ebs.template .
